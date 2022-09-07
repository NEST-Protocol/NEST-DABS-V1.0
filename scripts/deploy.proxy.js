// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const DabsGovernance = await ethers.getContractFactory('DabsGovernance');
    const DabsPlatform = await ethers.getContractFactory('DabsPlatform');
    const DabsLedger = await ethers.getContractFactory('DabsLedger');
    const DabsStableCoin = await ethers.getContractFactory('DabsStableCoin');
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestLedger = await ethers.getContractFactory('NestLedger');
    const NestBatchPlatform2 = await ethers.getContractFactory('NestBatchPlatform2');
    const CoFiXGovernance = await ethers.getContractFactory('CoFiXGovernance');
    const CoFiXRouter = await ethers.getContractFactory('CoFiXRouter');

    console.log('** Deploy: deploy.proxy.js **');
    
    // 1. Deploy dependent contract

    const nest = await TestERC20.deploy('nest', 'nest', 18);
    //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);

    const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    //const pusd = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('pusd: ' + pusd.address);

    const hbtc = await TestERC20.deploy('Huobi-BTC', 'HBTC', 18);
    //const hbtc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('hbtc: ' + hbtc.address);

    const dabsGovernance = await upgrades.deployProxy(DabsGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const dabsGovernance = await DabsGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('dabsGovernance: ' + dabsGovernance.address);

    const dabsPlatform = await upgrades.deployProxy(DabsPlatform, [dabsGovernance.address], { initializer: 'initialize' });
    //const dabsPlatform = await DabsPlatform.attach('0x0000000000000000000000000000000000000000');
    console.log('dabsPlatform: ' + dabsPlatform.address);

    const dabsLedger = await upgrades.deployProxy(DabsLedger, [dabsGovernance.address], { initializer: 'initialize' });
    //const dabsLedger = await DabsLedger.attach('0x0000000000000000000000000000000000000000');
    console.log('dabsLedger: ' + dabsLedger.address);

    const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const nestGovernance = await NestGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('nestGovernance: ' + nestGovernance.address);

    const nestLedger = await upgrades.deployProxy(NestLedger, [nestGovernance.address], { initializer: 'initialize' });
    //const nestLedger = await NestLedger.attach('0x0000000000000000000000000000000000000000');
    console.log('nestLedger: ' + nestLedger.address);

    const nestBatchPlatform2 = await upgrades.deployProxy(NestBatchPlatform2, [nestGovernance.address], { initializer: 'initialize' });
    //const nestBatchPlatform2 = await NestBatchPlatform2.attach('0x0000000000000000000000000000000000000000');
    console.log('nestBatchPlatform2: ' + nestBatchPlatform2.address);

    const cofixGovernance = await upgrades.deployProxy(CoFiXGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const cofixGovernance = await CoFiXGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixGovernance: ' + cofixGovernance.address);

    const cofixRouter = await upgrades.deployProxy(CoFiXRouter, [cofixGovernance.address], { initializer: 'initialize' });
    //const cofixRouter = await CoFiXRouter.attach('0x0000000000000000000000000000000000000000');
    console.log('cofixRouter: ' + cofixRouter.address);

    console.log('1. nestGovernance.setBuiltinAddress()');
    await dabsGovernance.setBuiltinAddress(
        dabsPlatform.address,
        dabsLedger.address,
        cofixRouter.address,
        nestBatchPlatform2.address,
        pusd.address
    );

    console.log('4. dabsPlatform.update()');
    await dabsPlatform.update(dabsGovernance.address);

    await cofixGovernance.setBuiltinAddress(
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        cofixRouter.address,
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000'
    );

    console.log('1. nestGovernance.setBuiltinAddress()');
    await nestGovernance.setBuiltinAddress(
        nest.address,
        '0x0000000000000000000000000000000000000000',
        nestLedger.address,
        '0x0000000000000000000000000000000000000000', //nestMining.address,
        '0x0000000000000000000000000000000000000000', //nestMining.address,
        nestBatchPlatform2.address, //nestPriceFacade.address,
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000', //nestMining.address,
        '0x0000000000000000000000000000000000000000', //nnIncome.address,
        '0x0000000000000000000000000000000000000000'  //nTokenController.address
    );

    console.log('2. nestLedger.update()');
    await nestLedger.update(nestGovernance.address);

    await cofixGovernance.setGovernance(dabsPlatform.address, 1);

    console.log('11. nestBatchPlatform2.setConfig()');
    await nestBatchPlatform2.setConfig({
        // -- Public configuration
        // The number of times the sheet assets have doubled. 4
        maxBiteNestedLevel: 4,
        
        // Price effective block interval. 20
        priceEffectSpan: 0,

        // The amount of nest to pledge for each post (Unit: 1000). 100
        pledgeNest: 100
    });

    console.log('12.nestBatchPlatform2.open()');
    await nestBatchPlatform2.open(
        pusd.address,
        2000000000000000000000n,
        nest.address,
        [hbtc.address, nest.address, eth.address], {
            rewardPerBlock: 100000000000000000n,
            postFeeUnit: 0n,
            singleFee: 0n,
            reductionRate: 8000n
        }
    );

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        pusd: pusd,
        hbtc: hbtc,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        nestBatchPlatform2: nestBatchPlatform2,
        dabsPlatform: dabsPlatform,

        cofixRouter: cofixRouter
    };

    return contracts;
};