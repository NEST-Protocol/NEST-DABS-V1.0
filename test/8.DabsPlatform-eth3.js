const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI, calcRevisedK } = require('./utils.js');

describe('8.DabsPlatform-eth3', function() {
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
            dabsPlatform,
            cofixRouter
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
        await nest.connect(addr1).transfer(addr1.address, 10000000000000000000000000n);
        await pusd.connect(addr1).transfer(addr1.address, 10000000000000000000000000n);
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

        let nestBatchPriceView = await ethers.getContractAt('INestBatchPriceView', nestBatchPlatform2.address);

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        if (true) {
            console.log('1. post');
            const N = 9n;
            const M = 10n;
            let receipt = await nestBatchPlatform2.connect(addr1).post(0, 1, [66666666666666700n * N / M, 62500000000000000000000n * N / M, 1000000000000000000n * N / M], {
                value: 1000000000000000000n * N / M
            });
            await showReceipt(receipt);
            let status = await showStatus();
        }
        if (true) {
            console.log('2. post');
            let receipt = await nestBatchPlatform2.connect(addr1).post(0, 1, [66666666666666700n, 62500000000000000000000n, 1000000000000000000n], {
                value: 1000000000000000000n
            });
            await showReceipt(receipt);
            let status = await showStatus();
        }

        const sigmaSQ = 1.02739726027397e-7;
        const estimateMint = async function(amount) {
            let prices = await nestBatchPriceView.lastPriceList(0, 2, 2);
            let currentBlock = parseInt(await ethers.provider.getBlockNumber());
            let k = calcRevisedK(sigmaSQ, prices[3], prices[2], prices[1], prices[0], currentBlock);
            console.log('k=' + k);
            let price = prices[1] * (1 + k);
            let value = amount * 2000e18 / price;
            return value;
        }

        const estimateBurn = async function(amount) {
            let prices = await nestBatchPriceView.lastPriceList(0, 2, 2);
            let currentBlock = parseInt(await ethers.provider.getBlockNumber());
            let k = calcRevisedK(sigmaSQ, prices[3], prices[2], prices[1], prices[0], currentBlock);
            console.log('k=' + k);
            let price = prices[1] / (1 + k);
            let value = amount * price / 2000e18;
            return value;
        }

        const aeq = function(a, b) {
            a = parseFloat(a);
            b = parseFloat(b);
            if (a == 0) {
                if (b == 0) {
                    return;
                }
                expect(Math.abs(b - a) / b).to.lt(1e-10);
            } else {
                expect(Math.abs(b - a) / a).to.lt(1e-10);
            }
        }

        // if (true) {
        //     console.log('2. price');
        //     await skipBlocks(1);
        //     let pi = await nestBatchPriceView.lastPriceList(0, 0, 1);
        //     console.log(UI(pi));
        // }

        console.log('3. create project');
        await dabsPlatform.open(0, 2, 2000);
        let project = (await dabsPlatform.list(0, 1, 1))[0];
        console.log(UI(project));

        const dabsStableCoin = DabsStableCoin.attach(project.stablecoin);
        stable = dabsStableCoin;
        
        let prev = 0;
        if (true) {
            console.log('4. mint');
            //await hbtc.approve(dabsPlatform.address, toBigInt(1000));
            await dabsPlatform.mintAndStake(0, toBigInt(100), { value: toBigInt(100) }); 
            let status = await showStatus();
            let v = await estimateMint(100);
            console.log('mint-v: ' + v);

            aeq(v, status.dabsPlatform.stable);

            prev = parseFloat(status.owner.eth);
        }

        if (false) {
            console.log('5. burn');
            let balance = await dabsStableCoin.balanceOf(owner.address);
            await dabsPlatform.burn(0, balance);
            let status = await showStatus();
            let v = await estimateBurn(parseFloat(toDecimal(balance)));
            let b = parseFloat(status.owner.eth) - prev;
            console.log('burn-v: ' + v);
            aeq(v, b);
        }

        let dabsStableCoinAmount = await dabsStableCoin.balanceOf(dabsPlatform.address);
        if (false) {
            console.log('6. stake');
            await dabsStableCoin.approve(dabsPlatform.address, toBigInt(10000000));
            await dabsPlatform.stake(0, dabsStableCoinAmount);
            let status = await showStatus();
        }

        const BN = 12;
        if (true) {
            console.log('7. earned');
            await skipBlocks(BN);
            let earned = await dabsPlatform.earned(0, owner.address);
            console.log('earned: ' + earned.toString());

            let v = dabsStableCoinAmount * BN * 20 / 2400000 / 100;
            console.log('earn-v: ' + v);
            aeq(v, earned);
        }

        if (true) {
            console.log('8. withdraw');
            await dabsPlatform.withdraw(0);
            let status = await showStatus();
            let d = parseFloat(status.owner.stable) - parseFloat(toDecimal(dabsStableCoinAmount));
            console.log('d=' + d);
            let v = parseFloat(toDecimal(dabsStableCoinAmount * (BN + 1) * 20 / 2400000 / 100));
            console.log('v=' + v);
            aeq(v, d);
        } else {
            console.log('8. getReward');
            await dabsPlatform.getReward(0);
            let status = await showStatus();
            let d = parseFloat(status.owner.stable);
            console.log('d=' + d);
            let v = parseFloat(toDecimal(dabsStableCoinAmount * (BN + 1) * 20 / 2400000 / 100));
            console.log('v=' + v);
            aeq(v, d);
        }

        if (true) {
            console.log('9. show name and symbol');
            console.log('name: ' + await dabsStableCoin.name());
            console.log('symbol: ' + await dabsStableCoin.symbol());
        }

        if (true) {
            console.log('10. burn');
            let balance = await dabsStableCoin.balanceOf(owner.address);
            await dabsPlatform.burn(0, balance);
            let status = await showStatus();
            let v = await estimateBurn(parseFloat(toDecimal(balance)));
            let b = parseFloat(status.owner.eth) - prev;
            console.log('burn-v: ' + v);
            aeq(v, b);
        }
    });
});
