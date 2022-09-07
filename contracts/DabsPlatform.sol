// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";

import "./nest/interfaces/INestBatchMining.sol";
import "./nest/interfaces/INestBatchPrice2.sol";
import "./cofix/interfaces/ICoFiXRouter.sol";

import "./interfaces/IDabsGovernance.sol";
import "./interfaces/IDabsPlatform.sol";
import "./interfaces/IDabsStableCoin.sol";
import "./interfaces/IDabsVaultForStaking.sol";

import "./DabsBase.sol";
import "./DabsStableCoin.sol";

/// @dev This contract implemented the mining logic of nest dabs
contract DabsPlatform is DabsBase, IDabsPlatform, IDabsVaultForStaking {

    // TODO: Set BTC address
    /// @dev Address of BTC
    address constant BTC_TOKEN_ADDRESS = address(0);

    // TODO: Set ETH address
    /// @dev Address of ETH
    address constant ETH_TOKEN_ADDRESS = address(0);

    /// @dev Post unit of target token in nest must be 2000 ether
    //uint constant uint POST_UNIT = 2000 ether;

    // Block average time
    uint constant BLOCK_TIME = 14;
    // Blocks in one year, 2400000 for ethereum
    uint constant ONE_YEAR_BLOCK = 2400000;

    // Address of CoFiXRouter
    address COFIX_ROUTER;

    // Address of DabsLedger
    address DABS_LEDGER;

    // Address of NestBatchPlatform
    address NEST_OPEN_PLATFORM;

    // Address of usdt
    address _usdtAddress;

    /// @dev Account information
    struct Account {
        // Staked of current account
        uint160 balance;
        // Token dividend value mark of the unit that the account has received
        uint96 blockCursor;
    }

    /// @dev Project configuration structure
    struct ProjectConfig {
        // // The channelId for call nest price
        // uint16 channelId;
        // // The pairIndex for call nest price
        // uint16 pairIndex;
        // // Reward rate
        // uint16 stakingRewardRate;
        // await nestOpenPool.setConfig(0, 1, 2000000000000000000000n, 30, 10, 2000, 102739726027n);
        // Standard sigmaSQ: eth, btc and other (use nest value)
        uint48 sigmaSQ;
    }

    /// @dev Project core information
    struct ProjectCore {
        // The channelId for call nest price
        uint16 channelId;
        // The pairIndex for call nest price
        uint16 pairIndex;
        // Reward rate, 10000 points system, 2000 means 20%
        uint16 stakingRewardRate;
        uint48 sigmaSQ;// = 102739726027;
        // Reserve token address
        address target;

        // Post unit of target token in nest
        uint96 postUnit;
        // Stablecoin address
        address stablecoin;
    }

    /// @dev Project information
    struct Project {
        
        // Core information
        ProjectCore core;

        // Opener of this project
        address opener;
        // Open block number
        uint32 openBlock;

        // Accounts
        // address=>balance
        mapping(address=>Account) accounts;
    }

    // Project array
    Project[] _projects;

    // Project mapping
    mapping(bytes32=>uint) _projectMapping;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        (
            , 
            DABS_LEDGER, 
            COFIX_ROUTER, 
            NEST_OPEN_PLATFORM, 
            _usdtAddress
        ) = IDabsGovernance(newGovernance).getBuiltinAddress();
    }

    // /// @dev UnRegister project
    // /// @param projectId project Index
    // function unRegister(uint projectId) external onlyGovernance {
    //     ProjectCore memory core = _projects[projectId].core;
    //     _projectMapping[_getKey(core.target, core.stablecoin)] = 0;
    // }
    
    /// @dev Find the projects of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param opener Target address
    /// @return projectArray Matched project array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address opener
    ) external view override returns (ProjectView[] memory projectArray) {
        projectArray = new ProjectView[](count);
        // Calculate search region
        Project[] storage projects = _projects;
        uint end = 0;
        if (start == 0) {
            start = projects.length;
        }
        if (start > maxFindCount) {
            end = start - maxFindCount;
        }
        
        // Loop lookup to write qualified records to the buffer
        for (uint index = 0; index < count && start > end;) {
            Project storage project = projects[--start];
            if (project.opener == opener) {
                projectArray[index++] = _toProjectView(project, start);
            }
        }
    }

    /// @dev List projects
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return projectArray Matched project array
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (ProjectView[] memory projectArray) {
        // Load projects
        Project[] storage projects = _projects;
        // Create result array
        projectArray = new ProjectView[](count);
        uint length = projects.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                Project storage project = projects[--index];
                projectArray[i++] = _toProjectView(project, index);
            }
        } 
        // Positive order
        else {
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                projectArray[i++] = _toProjectView(projects[index], index);
                ++index;
            }
        }
    }

    /// @dev Obtain the number of projects that have been opened
    /// @return Number of projects opened
    function getProjectCount() external view override returns (uint) {
        return _projects.length;
    }

    /// @dev Open new project
    /// @param channelId The channelId for call nest price
    /// @param pairIndex The pairIndex for call nest price
    /// @param stakingRewardRate Reward rate
    function open(
        uint16 channelId,
        uint16 pairIndex,
        uint16 stakingRewardRate
    ) external override {
        // Load channel information
        INestBatchMining.PriceChannelView memory ci = INestBatchMining(NEST_OPEN_PLATFORM).getChannelInfo(channelId);
        // Check channel
        require(ci.token0 == _usdtAddress, "NAP:token0 must be USDT");
        require(uint(ci.unit) > 0 && uint(ci.unit) < type(uint96).max, "NAP:unit must be 2000");

        address target = ci.pairs[pairIndex].target;
        uint projectId = _projects.length;

        // Create stablecoin
        address stablecoin = address(new DabsStableCoin(
            target == address(0) ?
                 "Stablecoin for ETH" : StringHelper.sprintf("Stablecoin for %s", abi.encode(ERC20(target).name())),
            target == address(0) ?
                "U-ETH" : StringHelper.sprintf("U-%4s", abi.encode(ERC20(target).symbol())),
            projectId
        ));
        
        emit NewProject(projectId, target, stablecoin, msg.sender);

        uint sigmaSQ;
        // Set sigmaSQ
        if (target == ETH_TOKEN_ADDRESS) {
            // ETH
            sigmaSQ = (45659142400);
        } else if (target == BTC_TOKEN_ADDRESS) {
            // BTC
            sigmaSQ = (31708924900);
        } else {
            // OTHER
            sigmaSQ = (102739726027);
        }

        // Create project information
        Project storage project = _projects.push();
        project.core = ProjectCore(
            channelId, 
            pairIndex, 
            stakingRewardRate, 
            uint48(sigmaSQ), 
            target, 
            uint96(ci.unit), 
            stablecoin
        );
        project.opener = msg.sender;
        project.openBlock = uint32(block.number);

        // Register to cofixRouter
        _projectMapping[_getKey(target, stablecoin)] = projectId + 1;
        ICoFiXRouter(COFIX_ROUTER).registerPair(target, stablecoin, address(this));
    }

    /// @dev Modify project configuration
    /// @param projectId project Index
    /// @param config project configuration
    function modify(uint projectId, ProjectConfig calldata config) external onlyGovernance {
        Project storage project = _projects[projectId];
        project.core.sigmaSQ = config.sigmaSQ;
    }

    /// @dev Swap token
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param to The target address receiving the ETH
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountOut The real amount of ETH transferred out of pool
    /// @return mined The amount of CoFi which will be mind by this trade
    function swap(
        address src, 
        address dest, 
        uint amountIn, 
        address to, 
        address payback
    ) external payable returns (
        uint amountOut, 
        uint mined
    ) {
        // Must from cofixRouter
        // Amount of src will be transfer to this contract by cofixRouter
        require(msg.sender == COFIX_ROUTER, "APF:not cofixRouter");
        
        // Load project information
        ProjectCore memory core = _projects[_projectMapping[_getKey(src, dest)] - 1].core;

        // Check src and dest
        require(src == core.target && dest == core.stablecoin, "APF:pair not allowed");

        uint fee = msg.value;
        if (core.target == address(0)) {
            fee -= amountIn;
            payable(core.stablecoin).transfer(amountIn);
        } else {
            TransferHelper.safeTransfer(core.target, core.stablecoin, amountIn);
        }

        _mintInternal(core, amountIn, to, fee, payback);

        mined = 0;
    }

    /// @dev Mint stablecoin with target token
    /// @param projectId project Index
    /// @param amount Amount of target token
    function mint(uint projectId, uint amount) external payable override {
        // Load project
        ProjectCore memory core = _projects[projectId].core;
        
        uint fee = msg.value;
        if (core.target == address(0)) {
            fee -= amount;
            payable(core.stablecoin).transfer(amount);
        } else {
            TransferHelper.safeTransferFrom(core.target, msg.sender, core.stablecoin, amount);
        }

        _mintInternal(core, amount, msg.sender, fee, msg.sender);
    }

    /// @dev Burn stablecoin and get target token
    /// @param projectId project Index
    /// @param amount Amount of stablecoin
    function burn(uint projectId, uint amount) external payable override {
        // Load project
        ProjectCore memory core = _projects[projectId].core;
        address stablecoin = core.stablecoin;

        // Query oracle price
        uint oraclePrice = _queryPrice(core, 0, false, msg.value, msg.sender);
        uint value = amount * oraclePrice / uint(core.postUnit);

        // Burn
        IDabsStableCoin(stablecoin).burn(msg.sender, amount);
        // Pay
        IDabsStableCoin(stablecoin).pay(core.target, msg.sender, value);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @dev Get staked amount of target address
    /// @param projectId project Index
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(uint projectId, address addr) external view override returns (uint) {
        return uint(_projects[projectId].accounts[addr].balance);
    }

    /// @dev Get the amount of reward
    /// @param projectId project Index
    /// @param addr Target address
    /// @return The amount of reward
    function earned(uint projectId, address addr) external view override returns (uint) {
        // Load project
        Project storage project = _projects[projectId];
        // Call _calcReward() to calculate new reward
        return _calcReward(project, project.accounts[addr]);
    }

    /// @dev Stake stablecoin and to earn reward
    /// @param projectId project Index
    /// @param amount Stake amount
    function stake(uint projectId, uint amount) external override {

        // Load stake channel
        Project storage project = _projects[projectId];
        
        // Transfer stable from msg.sender to this
        TransferHelper.safeTransferFrom(project.core.stablecoin, msg.sender, address(this), uint(amount));
        
        // Settle reward for account
        Account memory account = project.accounts[msg.sender];

        // Update stake balance of account
        account.balance = _toUInt160(uint(account.balance) + amount + _updateReward(project, account));
        //account.blockCursor = uint96(block.number);

        project.accounts[msg.sender] = account;
    }

    /// @dev Mint stablecoin with target token
    /// @param projectId project Index
    /// @param amount Amount of target token
    function mintAndStake(uint projectId, uint amount) external payable override {
        // Load project
        Project storage project = _projects[projectId];
        ProjectCore memory core = project.core;
        
        uint fee = msg.value;
        if (core.target == address(0)) {
            fee -= amount;
            payable(core.stablecoin).transfer(amount);
        } else {
            TransferHelper.safeTransferFrom(core.target, msg.sender, core.stablecoin, amount);
        }

        uint value = _mintInternal(core, amount, address(this), fee, msg.sender);

        // Settle reward for account
        Account memory account = project.accounts[msg.sender];

        // Update stake balance of account
        account.balance = _toUInt160(uint(account.balance) + value + _updateReward(project, account));
        //account.blockCursor = uint96(block.number);

        project.accounts[msg.sender] = account;
    }

    /// @dev Withdraw stablecoin and claim reward
    /// @param projectId project Index
    function withdraw(uint projectId) external override {
        // Load stake channel
        Project storage project = _projects[projectId];

        // Settle reward for account
        Account memory account = project.accounts[msg.sender];
        uint amount = uint(account.balance) + _updateReward(project, account);

        // Update stake balance of account
        account.balance = uint160(0);
        //account.blockCursor = uint96(block.number);
        project.accounts[msg.sender] = account;

        // Transfer stablecoin to msg.sender
        TransferHelper.safeTransfer(project.core.stablecoin, msg.sender, amount);
    }

    /// @dev Claim reward
    /// @param projectId project Index
    function getReward(uint projectId) external override {
        Project storage project = _projects[projectId];
        Account memory account = project.accounts[msg.sender];
        project.accounts[msg.sender] = account;
        TransferHelper.safeTransfer(project.core.stablecoin, msg.sender, _updateReward(project, account));
        // account.blockCursor = uint96(block.number);
    }

    /// @dev Calculate the impact cost
    /// @param vol Trade amount in usdt
    /// @return Impact cost
    function impactCost(uint vol) public pure override returns (uint) {
        //impactCost = vol / 10000 / 1000;
        //return vol / 10000000;
        require(vol >= 0, "APF:nop");
        return 0;
    }

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ sigmaSQ for token
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) public view override returns (uint k) {
        uint sigmaISQ = p * 1 ether / p0;
        if (sigmaISQ > 1 ether) {
            sigmaISQ -= 1 ether;
        } else {
            sigmaISQ = 1 ether - sigmaISQ;
        }

        // The left part change to: Max((p2 - p1) / p1, 0.002)
        if (sigmaISQ > 0.002 ether) {
            k = sigmaISQ;
        } else {
            k = 0.002 ether;
        }

        sigmaISQ = sigmaISQ * sigmaISQ / (bn - bn0);

        if (sigmaISQ > sigmaSQ * BLOCK_TIME * 1 ether) {
            k += _sqrt(sigmaISQ * (block.number - bn));
        } else {
            k += _sqrt(1 ether * BLOCK_TIME * sigmaSQ * (block.number - bn));
        }
    }

    // Calculate sqrt of x
    function _sqrt(uint256 x) private pure returns (uint256) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
                if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
                if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
                if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
                if (xx >= 0x100) { xx >>= 8; r <<= 4; }
                if (xx >= 0x10) { xx >>= 4; r <<= 2; }
                if (xx >= 0x8) { r <<= 1; }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }
    
    // Generate the mapping key based on the token address
    function _getKey(address token0, address token1) private pure returns (bytes32) {
        (token0, token1) = _sort(token0, token1);
        return keccak256(abi.encodePacked(token0, token1));
    }

    // Sort the address pair
    function _sort(address token0, address token1) private pure returns (address min, address max) {
        if (token0 < token1) {
            min = token0;
            max = token1;
        } else {
            min = token1;
            max = token0;
        }
    }

    // Ming logic    
    function _mintInternal(
        ProjectCore memory core, 
        uint amount, 
        address to, 
        uint fee, 
        address payback
    ) private returns (uint value) {

        uint oraclePrice = _queryPrice(core, 0, true, fee, payback);

        // Calculate mint value
        value = uint(core.postUnit) * amount / oraclePrice;

        // Mint
        IDabsStableCoin(core.stablecoin).mintEx(to, value, DABS_LEDGER, value / 100);
    }

    /// @dev Query price
    /// @param core Target project core information
    /// @param scale Scale of this transaction
    /// @param enlarge Modify the OraclePrice, enlarge or reduce
    /// @param fee Oracle fee
    /// @param payback Address to receive refund
    function _queryPrice(
        ProjectCore memory core,
        uint scale, 
        bool enlarge, 
        uint fee,
        address payback
    ) private returns (uint oraclePrice) {

        // Query price from oracle
        uint[] memory pairIndices = new uint[](1);
        pairIndices[0] = uint(core.pairIndex);
        uint[] memory prices = INestBatchPrice2(NEST_OPEN_PLATFORM).lastPriceList {
            value: fee
        } (uint(core.channelId), pairIndices, 2, payback);

        // Convert to usdt based price
        oraclePrice = prices[1];
        uint k = calcRevisedK(uint(core.sigmaSQ), prices[3], prices[2], oraclePrice, prices[0]);

        // Make corrections to the price
        if (enlarge) {
            oraclePrice = oraclePrice * (1 ether + k + impactCost(scale)) / 1 ether;
        } else {
            oraclePrice = oraclePrice * 1 ether / (1 ether + k + impactCost(scale));
        }
    }
    
    // Calculate new reward
    function _calcReward(Project storage project, Account memory account) private view returns (uint newReward) {
        // Call _calcReward() to calculate new reward
        return uint(account.balance) * uint(project.core.stakingRewardRate) * (block.number - account.blockCursor) 
                / ONE_YEAR_BLOCK / 10000;
    }

    // Update account
    function _updateReward(Project storage project, Account memory account) private returns (uint newReward) {
        // Call _calcReward() to calculate new reward
        newReward = _calcReward(project, account);
        IDabsStableCoin(project.core.stablecoin).mint(address(this), newReward);
        account.blockCursor = uint96(block.number);
    }

    // Convert uint to uint160
    function _toUInt160(uint v) private pure returns (uint160) {
        require(v <= type(uint160).max, "APF:can't convert to uint160");
        return uint160(v);
    }

    // Convert to ProjectView
    function _toProjectView(Project storage project, uint index) private view returns (ProjectView memory projectView) {
        projectView = ProjectView(
            index,
            project.core.channelId,
            project.core.pairIndex,
            project.core.stakingRewardRate,
            project.core.sigmaSQ,
            project.core.target,
            project.core.postUnit,
            project.core.stablecoin,
            project.opener,
            project.openBlock
        );
    }
}