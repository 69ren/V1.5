import { ethers, upgrades } from "hardhat";
import { Booster, BribeSwappoor, ElmoSOLID, EnneadProxyDeployer, FeeHandler, MultiRewards, PoolRouter, Rewarder, VeDepositor } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export type Ennead = {
    deployer: SignerWithAddress,
    enneadDeployer: EnneadProxyDeployer,
    booster: Booster,
    ve: VeDepositor,
    router: PoolRouter,
    swap: BribeSwappoor,
    rewards: MultiRewards,
    fees: FeeHandler,
    tokenStaking: ElmoSOLID,
    pool: Rewarder,
    proxyAdminAddress: string
}

export async function deploy(config: any) {
    const [
        EnneadDeployer,
        Booster,
        veDepositor,
        PoolRouter,
        Swappoor,
        MultiRewards,
        FeeHandler,
        elmo
    ] = await Promise.all([
        ethers.getContractFactory("contracts/EnneadDeployer.sol:EnneadProxyDeployer"),
        ethers.getContractFactory("contracts/Booster.sol:Booster"),
        ethers.getContractFactory("contracts/veDepositor.sol:VeDepositor"),
        ethers.getContractFactory("contracts/PoolRouter.sol:PoolRouter"),
        ethers.getContractFactory("contracts/Swappoor.sol:bribeSwappoor"),
        ethers.getContractFactory("contracts/MultiRewards.sol:multiRewards"),
        ethers.getContractFactory("contracts/FeeHandler.sol:feeHandler"),
        ethers.getContractFactory("contracts/elmo.sol:elmoSOLID")
    ]);
    const Pool = await ethers.getContractFactory("contracts/Pool.sol:Rewarder")

    const [deployer] = await ethers.getSigners();

    const proxyAdminAddress = await upgrades.deployProxyAdmin();
    const enneadDeployer = (await upgrades.deployProxy(EnneadDeployer, [proxyAdminAddress, deployer.address, deployer.address])) as EnneadProxyDeployer
    await enneadDeployer.deployMany(config.salts)
    const proxies = await enneadDeployer.getDeployedProxies()

    const factories = {Booster, veDepositor, PoolRouter, Swappoor, MultiRewards, FeeHandler, elmo}
    let i = 0;
    for (const Factory of Object.values(factories)) {
        const implementation = await Factory.deploy();
        await implementation.deployTransaction.wait();
        await implementation.deployed();

        const proxy = await ethers.getContractAt("EnneadProxy", proxies[i]);
        await proxy.initialize(implementation.address, '0x');
        i++;
    }
    
    const booster = Booster.attach(proxies[0]) as Booster
    const ve = veDepositor.attach(proxies[1]) as VeDepositor
    const router = PoolRouter.attach(proxies[2]) as PoolRouter
    const swap = Swappoor.attach(proxies[3]) as BribeSwappoor
    const rewards = MultiRewards.attach(proxies[4]) as MultiRewards
    const fees = FeeHandler.attach(proxies[5]) as FeeHandler
    const tokenStaking = elmo.attach(proxies[6]) as ElmoSOLID
    const pool = await upgrades.deployBeacon(Pool) as Rewarder

    await booster.initialize(config.voter, config.MULTISIG, config.operator, config.operator, config.operator, proxyAdminAddress)
    await booster.setAddresses(ve.address, fees.address, router.address)
    await ve.initialize(config.ram, config.votingEscrow, config.veDist, config.MULTISIG, config.operator, config.operator, proxyAdminAddress)
    await ve.setAddresses(booster.address, tokenStaking.address)
    await swap.initialize(config.MULTISIG, config.operator, proxyAdminAddress)
    await rewards.initialize(tokenStaking.address, config.MULTISIG, config.operator, fees.address, proxyAdminAddress)
    await fees.initialize(config.MULTISIG, config.operator, config.operator, proxyAdminAddress, swap.address, booster.address)
    await tokenStaking.initialize(ve.address, config.MULTISIG, config.operator, config.operator, proxyAdminAddress)
    await router.initialize(pool.address, booster.address, config.MULTISIG, config.operator, config.operator, proxyAdminAddress)
    
    console.log('Done')

    return {
        deployer,
        enneadDeployer,
        booster,
        ve,
        router,
        swap,
        rewards,
        fees,
        tokenStaking,
        pool,
        proxyAdminAddress
    }
}
