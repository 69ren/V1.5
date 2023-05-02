import { ethers } from "hardhat"
import {deploy} from "./deploy"

export async function testDeploy() {
    const [deployer] = await ethers.getSigners()
    const multisig = deployer.address

    const testConfig = {
        MULTISIG: multisig,
        voter: "0xAAA2564DEb34763E3d05162ed3f5C2658691f499",
        ram: "0xAAA6C1E32C55A7Bfa8066A6FAE9b42650F262418",
        votingEscrow: "0xAAA343032aA79eE9a6897Dab03bef967c3289a06",
        veDist: "0xAAA86B908A3B500A0DE661301ea63966923a97b1",
        salts: [1, 2, 3, 4, 5, 6, 7],
        operator: multisig
    }

    const ennead = await deploy(testConfig)
    return ennead
}