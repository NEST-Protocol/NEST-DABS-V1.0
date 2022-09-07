const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('1.DabsPlatform-test', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const DabsStableCoin = await ethers.getContractFactory('DabsStableCoin');

        let stable = { balanceOf: async function(account) { return 0; } };
        const { 
            nest,
            pusd,
            hbtc,
    
            nestGovernance,
            nestLedger,
            nestBatchPlatform2,
            dabsPlatform
        } = await deploy();

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                pusd: toDecimal(await pusd.balanceOf(account), 6),
                hbtc: toDecimal(await hbtc.balanceOf(account), 18),
                nest: toDecimal(await nest.balanceOf(account), 18),
                stable: toDecimal(await stable.balanceOf(account), 18)
            };
        };

        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                nestBatchPlatform2: await getAccountInfo(nestBatchPlatform2),
                dabsPlatform: await getAccountInfo(dabsPlatform),
            };
        };

        const showStatus = async function() {
            let status = await getStatus();
            console.log(status);
            return status;
        };

        const skipBlocks = async function(n) {
            for (var i = 0; i < n; ++i) {
                await pusd.transfer(owner.address, 0);
            }
        };

        await pusd.transfer(owner.address, 10000000000000000000000000n);
        await hbtc.transfer(owner.address, 10000000000000000000000000n);
        await pusd.connect(addr1).transfer(addr1.address, 10000000000000n);
        await hbtc.connect(addr1).transfer(addr1.address, 10000000000000000000000000n);
        await nest.transfer(owner.address, 10000000000000000000000000000n);
        console.log(await getStatus());

        await nest.approve(nestBatchPlatform2.address, 10000000000000000000000000000n);
        await pusd.approve(nestBatchPlatform2.address, 10000000000000000000000000n);
        await hbtc.approve(nestBatchPlatform2.address, 10000000000000000000000000n);
        await nest.connect(addr1).approve(nestBatchPlatform2.address, 10000000000000000000000000000n);
        await pusd.connect(addr1).approve(nestBatchPlatform2.address, 10000000000000000000000000n);
        await hbtc.connect(addr1).approve(nestBatchPlatform2.address, 10000000000000000000000000n);

        await nestBatchPlatform2.increase(0, 5000000000000000000000000000n);
        await nest.approve(nestBatchPlatform2.address, 10000000000000000000000000000n);
        console.log(await getStatus());

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        if (true) {
            console.log('1. post');
            let receipt = await nestBatchPlatform2.post(0, 1, [66666666666666700n, 62500000000000000000000n, 1000000000000000000n], {
                value: 1000000000000000000n
            });
            await showReceipt(receipt);
            let status = await showStatus();
        }
        if (true) {
            console.log('2. post');
            let receipt = await nestBatchPlatform2.post(0, 1, [66666666666666700n, 62500000000000000000000n, 1000000000000000000n], {
                value: 1000000000000000000n
            });
            await showReceipt(receipt);
            let status = await showStatus();
        }

        if (true) {
            console.log('2. price');
            let no = await ethers.getContractAt('INestBatchPriceView', nestBatchPlatform2.address);
            await skipBlocks(1);
            let pi = await no.lastPriceList(0, 0, 1);
            console.log(pi);
        }

        
        console.log('3. create project');
        await dabsPlatform.open(0, 0, 2000);
        let project = (await dabsPlatform.list(0, 1, 1))[0];
        console.log(project);

        const dabsStableCoin = DabsStableCoin.attach(project.stablecoin);
        stable = dabsStableCoin;
        
        if (true) {
            console.log('4. mint');
            await hbtc.approve(dabsPlatform.address, toBigInt(1000));
            await dabsPlatform.mint(0, toBigInt(100), { value: 0n }); 
            let status = await showStatus();
        }

        if (false) {
            console.log('5. burn');
            await dabsPlatform.burn(0, await dabsStableCoin.balanceOf(owner.address));
            let status = await showStatus();
        }

        if (true) {
            console.log('6. stake');
            await dabsStableCoin.approve(dabsPlatform.address, toBigInt(10000000));
            await dabsPlatform.stake(0, await dabsStableCoin.balanceOf(owner.address));
            let status = await showStatus();
        }

        if (true) {
            console.log('7. earned');
            await skipBlocks(1);
            let earned = await dabsPlatform.earned(0, owner.address);
            console.log('earned: ' + earned.toString());
        }

        if (true) {
            console.log('8. withdraw');
            await dabsPlatform.withdraw(0);
            let status = await showStatus();
        }
    });
});
