const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('deploy', function() {
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

        await hbtc.approve(dabsPlatform.address, toBigInt(10000000));
    });
});
