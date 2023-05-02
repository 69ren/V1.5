import { time, mine, loadFixture, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { BigNumber, BigNumberish } from 'ethers';
import { testDeploy } from "../scripts/testDeployment";
import { Ennead } from "../scripts/deploy";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BaseERC20, Rewarder, contracts } from "../typechain-types";
import { Gauge, VotingEscrow } from "../Ramses/typechain-types"
import veABI from "../Ramses/artifacts/contracts/VotingEscrow.sol/VotingEscrow.json"
import gaugeABI from "../Ramses/artifacts/contracts/Gauge.sol/Gauge.json"

const MAX_UINT = BigNumber.from('0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff');
const frxEth  = "0x3932192dE4f17DFB94Be031a8458E215A44BF560";
const lusdDeiAddress = "0x6b18AE9225011eaf4A7e52f1069fB66462406bF0";

describe("General test", function () {
  let ennead: Ennead
  let user: SignerWithAddress
  let user2: SignerWithAddress
  let ram: BaseERC20
  let votingEscrow: VotingEscrow
  let tokenId: BigNumber
  let lusdDei: BaseERC20
  let gauge: Gauge
  let pool: Rewarder
  let amount: BigNumber

  before(async () => {
    ennead = await loadFixture(testDeploy);
    user = await ethers.getImpersonatedSigner("0xCF2C2fdc9A5A6fa2fc237DC3f5D14dd9b49F66A3");

    [,user2] = await ethers.getSigners()
    ram = await ethers.getContractAt("BaseERC20", "0xAAA6C1E32C55A7Bfa8066A6FAE9b42650F262418")
    votingEscrow = await ethers.getContractAtFromArtifact(veABI, "0xAAA343032aA79eE9a6897Dab03bef967c3289a06") as VotingEscrow
    await ram.connect(user).approve(ennead.ve.address, MAX_UINT)
    await ram.connect(user).approve(votingEscrow.address, MAX_UINT)
    await votingEscrow.connect(user).create_lock(ethers.utils.parseEther("1"), BigNumber.from(604800))
    tokenId = await votingEscrow.tokenOfOwnerByIndex(user.address, 1)
    lusdDei = await ethers.getContractAt("BaseERC20", lusdDeiAddress)
    await lusdDei.connect(user).approve(ennead.router.address, MAX_UINT)
    gauge = await ethers.getContractAtFromArtifact(gaugeABI, "0xfc315F415ADc2Ca29167d8648728A0d177dcf49E") as Gauge
    amount = ethers.utils.parseEther("100")

  })

  // veDepositor tests start here
  it("Should receive a veNFT and mint neadRam in a 1:1 ratio", async function () {
    await votingEscrow.connect(user)["safeTransferFrom(address,address,uint256)"](user.address, ennead.ve.address, tokenId)
    expect(tokenId).eq(await ennead.ve.tokenID())
    expect(await ennead.ve.balanceOf(user.address)).eq(ethers.utils.parseEther("1"))
  })

  it("Should handle ram deposits properly", async function () {
    let bal = await votingEscrow.balanceOfNFT(tokenId)
    await ennead.ve.connect(user).depositTokens(amount)
    expect(await votingEscrow.balanceOfNFT(tokenId)).greaterThan(bal)
    expect(await ennead.ve.balanceOf(user.address)).eq(ethers.utils.parseEther("101"))
  })

  it("Should not revert when extending lock", async function () {
    await expect(ennead.ve.extendLockTime()).to.not.reverted
  })

  it("Should handle veNFT transfers that werent done with safeTransferFrom", async function () {
    await votingEscrow.connect(user).create_lock(amount, 604800)
    let id = await votingEscrow.tokenOfOwnerByIndex(user.address, 1)
    await votingEscrow.connect(user).transferFrom(user.address, ennead.ve.address, id)
    let bal = await votingEscrow.balanceOfNFT(tokenId)
    await ennead.ve.connect(user).merge(id)
    expect(await votingEscrow.balanceOfNFT(tokenId)).greaterThan(bal)
  })
  
  // Booster tests starts here
  it("Should return the same tokenID as veDepositor", async function () {
    expect(await ennead.ve.tokenID()).eq(await ennead.booster.tokenID())
  })

  // pool or balance is irrelevant because it should revert before executing anything else
  it("Should revert when the caller of deposit is not neadPool", async function () {
    await expect(ennead.booster.depositInGauge(frxEth, ethers.utils.parseEther("1"))).to.be.revertedWith("!neadPool")
  })

  it("Should revert when the caller of withdraw is not neadPool", async function () {
    await expect(ennead.booster.withdrawFromGauge(frxEth, ethers.utils.parseEther("1"))).to.be.revertedWith("!neadPool")
  })

  it("Should revert when anyone who isn't neadPool tries to claim rewards", async function () {
    await expect(ennead.booster.getRewardFromGauge(frxEth, [frxEth])).to.be.revertedWith("!neadPool")
  })

  // PoolRouter tests
  it("Should not have any issues depositing lp tokens", async function () {
    let bal = await gauge.balanceOf(ennead.booster.address)
    await ennead.router.connect(user).deposit(lusdDeiAddress, amount)
    expect(await gauge.balanceOf(ennead.booster.address)).greaterThan(bal)
    let tokenForPool = await ennead.router.tokenForPool(lusdDeiAddress)
    pool = await ethers.getContractAt("Rewarder", tokenForPool)
    let tokenBal = await pool.balanceOf(user.address)
    expect(tokenBal).eq(await gauge.balanceOf(ennead.booster.address)) // neadPool receipt tokens are minted in a 1:1 ratio
    expect(await pool.totalSupply()).eq(amount)
    expect(await pool.totalSupply()).eq(tokenBal)
  });

  // fees are set to 0 for testing
  it("Should claim the correct amounts from gauge", async function () {
    await time.increase(3600) // increase time to accrue rewards
    let estimatedEarned = await pool.earned(user.address, [ram.address]) // This is an estimate and not accurate until checkpoints have been updated
   
    let balanceBefore = await ram.balanceOf(user.address)
    await pool.connect(user).getReward(user.address)
    let balanceAfter = await ram.balanceOf(user.address)
    expect(balanceAfter).greaterThan(balanceBefore)
    expect(balanceAfter.sub(balanceBefore)).greaterThanOrEqual(estimatedEarned[0])
  })

  it("Should not have any issues withdrawing lp tokens", async function () {
    await time.increase(3600)
    await ennead.router.connect(user).withdraw(lusdDeiAddress, amount)
    expect(await gauge.balanceOf(ennead.booster.address)).eq(0) // Only 1 user, if he withdraws there shouldnt be any balance in gauge
    let tokenBal = await pool.balanceOf(user.address)
    expect(tokenBal).eq(0)
    expect(await lusdDei.balanceOf(user.address)).eq(amount)
    expect(await pool.totalSupply()).eq(0)
  })

  it("Should allow claiming even if totalSupply == 0", async function () {
    let estimatedEarned = await pool.earned(user.address, [ram.address]) // This is an estimate and not accurate until checkpoints have been updated
    let balanceBefore = await ram.balanceOf(user.address)
    await pool.connect(user).getReward(user.address)
    let balanceAfter = await ram.balanceOf(user.address)
    expect(balanceAfter.sub(balanceBefore)).greaterThanOrEqual(estimatedEarned[0])
  })

  it("Should transfer the pool tokens successfuly", async function () {
    await ennead.router.connect(user).deposit(lusdDeiAddress, amount)
    await pool.connect(user).transfer(user2.address, amount)
    expect(await pool.balanceOf(user.address)).eq(0)
    expect(await pool.balanceOf(user2.address)).eq(amount)
  })

  it("Should stop accruing rewards for previous holder after transferring", async function () {
    await time.increase(3600)
    await pool.connect(user2).transfer(user.address, amount)
    let estimatedEarned = await pool.earned(user2.address, [ram.address])
    await time.increase(3600)
    let estimatedEarnedAfter = await pool.earned(user2.address, [ram.address])
    expect(estimatedEarnedAfter[0]).eq(estimatedEarned[0])
    // make sure user doesnt lose kek
    expect(estimatedEarned[0]).greaterThan(0)
  })

  it("Should still allow previous holder to claim rewards", async function () {
    let balanceBefore = await ram.balanceOf(user2.address)
    await pool.connect(user2).getReward(user2.address)
    expect(await ram.balanceOf(user2.address)).greaterThan(balanceBefore)
  })

  it("Should accrue rewards for the new holder", async function () {
    let estimatedEarned = await pool.earned(user.address, [ram.address])
    await time.increase(3600)
    let estimatedEarnedAfter = await pool.earned(user.address, [ram.address])
    expect(estimatedEarnedAfter[0]).greaterThan(estimatedEarned[0])
  })

  it("Should allow new holder to claim rewards", async function() {
    let balanceBefore = await ram.balanceOf(user.address)
    await pool.connect(user).getReward(user.address)
    expect(await ram.balanceOf(user.address)).greaterThan(balanceBefore)
  })

  it("Must not allow previous holder to withdraw", async function () {
    await expect(pool.connect(user2).withdraw(user2.address, amount)).to.be.reverted
  })

  it("Must not allow anyone to withdraw somebody elses tokens", async function () {
    await expect(pool.connect(user2).withdraw(user.address, amount)).to.be.reverted
  } )

  it("Must allow the new holder to withdraw tokens", async function () {
    pool.connect(user).withdraw(user.address, amount)
    expect(await lusdDei.balanceOf(user.address)).eq(amount)
  })
});
