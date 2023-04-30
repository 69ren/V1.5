import { ethers, network, upgrades } from "hardhat";
import { Booster, BribeSwappoor, ElmoSOLID, EnneadProxyDeployer, FeeHandler, MultiRewards, PoolRouter, VeDepositor } from "../typechain-types";

const MULTISIG = "0xE0474827e6Ec1953300f4eFaB36Bcfd535FB7E44"
const _voter = "0xAAA2564DEb34763E3d05162ed3f5C2658691f499"
const ram = "0xAAA6C1E32C55A7Bfa8066A6FAE9b42650F262418"
const votingEscrow = "0xAAA343032aA79eE9a6897Dab03bef967c3289a06"
const veDist = "0xAAA86B908A3B500A0DE661301ea63966923a97b1"
const salts = [1,2,3,4,5,6,7]

async function deploy() {
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

    await enneadDeployer.deployMany(salts)
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
    const pool = await upgrades.deployBeacon(Pool)

    await booster.initialize(_voter, deployer.address, deployer.address, deployer.address, deployer.address)
    await booster.setAddresses(ve.address, fees.address, router.address)
    await ve.initialize(ram, votingEscrow, veDist, deployer.address, deployer.address, deployer.address)
    await ve.setAddresses(booster.address, tokenStaking.address)
    await swap.initialize(deployer.address)
    await rewards.initialize(tokenStaking.address, deployer.address, deployer.address, deployer.address)
    await fees.initialize(deployer.address, swap.address, booster.address)
    await tokenStaking.initialize(ve.address, deployer.address, deployer.address, deployer.address)
    await router.initialize(pool.address,booster.address)
    
    console.log('Done')
}

deploy().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });