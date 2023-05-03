import { time, loadFixture, setBalance } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { BigNumber } from 'ethers';
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

// for setting up swapper
const tokens = [
  "0xe80772eaf6e2e18b651f160bc9158b2a5cafca65",
  "0xeb8e93a0c7504bffd8a8ffa56cd754c63aaebfe8",
  "0xd85e038593d7a098614721eae955ec2022b9b91b",
  "0xbb85d38faa5064fab8bf3e0a79583a2670f03dbc",
  "0x6aa395f06986ea4efe0a4630c7865c1eb08d5e7e",
  "0x9d2f299715d94d8a7e6f5eaa8e654e8c74a988a7",
  "0x1819e21698b777b69f903ff5550361cf12ed1def",
  "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9",
  "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a",
  "0xde1e704dae0b4051e80dabb26ab6ad6c12262da0",
  "0xad435674417520aeeed6b504bbe654d4f556182f",
  "0x17fc002b466eec40dae837fc4be5c67993ddbd6f",
  "0xaae0c3856e665ff9b3e2872b6d75939d810b7e40",
  "0x3f56e0c36d275367b8c502090edf38289b3dea0d",
  "0x6a7661795c374c0bfc635934efaddff3a7ee23b6",
  "0x93b346b6bc2548da6a1e7d98e9a421b42541425b",
  "0x4945970efeec98d393b4b979b9be265a3ae28a8b",
  "0xec13336bbd50790a00cdc0feddf11287eaf92529",
  "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9",
  "0xcaa38bcc8fb3077975bbe217acfaa449e6596a84"
]
const bridges = [
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xe80772eaf6e2e18b651f160bc9158b2a5cafca65",
  "0x3f56e0c36d275367b8c502090edf38289b3dea0d",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0x17fc002b466eec40dae837fc4be5c67993ddbd6f",
  "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xfb9e5d956d889d91a82737b9bfcdac1dce3e1449",
  "0xec13336bbd50790a00cdc0feddf11287eaf92529",
  "0xaae0c3856e665ff9b3e2872b6d75939d810b7e40",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8",
  "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8"
]
const stable = [
  true,
  true,
  true,
  false,
  false,
  false,
  false,
  true,
  true,
  true,
  false,
  true,
  false,
  true,
  true,
  false,
  false,
  false,
  true,
  false
]

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
  let ramFaucet: SignerWithAddress
  let wethFaucet:SignerWithAddress
  let deiFaucet: SignerWithAddress
  let weth: BaseERC20
  let dei: BaseERC20

  before(async () => {
    ennead = await loadFixture(testDeploy);
    
    user = await ethers.getImpersonatedSigner("0xCF2C2fdc9A5A6fa2fc237DC3f5D14dd9b49F66A3");
    ramFaucet = await ethers.getImpersonatedSigner("0xAAA343032aA79eE9a6897Dab03bef967c3289a06");
    wethFaucet = await ethers.getImpersonatedSigner("0x489ee077994B6658eAfA855C308275EAd8097C4A")
    deiFaucet = await ethers.getImpersonatedSigner("0x43fFC1291c2CC69cc5E4b12f8017AAAa696932e6")

    setBalance(deiFaucet.address, MAX_UINT);
    setBalance(wethFaucet.address, MAX_UINT);
    setBalance(ramFaucet.address, MAX_UINT);

    dei = await ethers.getContractAt("BaseERC20", "0xDE1E704dae0B4051e80DAbB26ab6ad6c12262DA0")
    weth = await ethers.getContractAt("BaseERC20", "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1");
    [,user2] = await ethers.getSigners()
    ram = await ethers.getContractAt("BaseERC20", "0xAAA6C1E32C55A7Bfa8066A6FAE9b42650F262418")
    votingEscrow = await ethers.getContractAtFromArtifact(veABI, "0xAAA343032aA79eE9a6897Dab03bef967c3289a06") as VotingEscrow
    await ram.connect(user).approve(ennead.ve.address, MAX_UINT)
    await ram.connect(user).approve(votingEscrow.address, MAX_UINT)
    await ram.connect(ramFaucet).transfer(user.address, ethers.utils.parseEther("1000"))
    await votingEscrow.connect(user).create_lock(ethers.utils.parseEther("1"), BigNumber.from(604800))
    tokenId = await votingEscrow.tokenOfOwnerByIndex(user.address, 1)
    lusdDei = await ethers.getContractAt("BaseERC20", lusdDeiAddress)
    await lusdDei.connect(user).approve(ennead.router.address, MAX_UINT)
    gauge = await ethers.getContractAtFromArtifact(gaugeABI, "0xfc315F415ADc2Ca29167d8648728A0d177dcf49E") as Gauge
    amount = ethers.utils.parseEther("100")
    await ennead.swap.addBridgeTokenBulk(tokens, bridges, stable)
    let callfee = ethers.utils.parseEther("0.01")
    await ennead.fees.setCallFees(callfee, callfee)
  })

  it("Should set rewards fees correctly", async function () {
    let platformFee = ethers.utils.parseEther("0.15")
    let stakerFee = ethers.utils.parseEther("0.1")
    let treasuryFee = ethers.utils.parseEther("0.05")
    await ennead.fees.connect(ennead.deployer).setRewardsFees(platformFee, treasuryFee, stakerFee)
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
    await expect(ennead.ve.extendLockTime()).to.not.be.reverted
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
    await pool.connect(user).withdraw(user.address, amount)
    expect(await lusdDei.balanceOf(user.address)).eq(amount)
  })

  // elmo tests start here, not checking erc4626 logic as it's minimally modified from the OZ implementation
  it("Should allow users to deposit and withdraw elmo", async function () {
    let bal = await ennead.ve.balanceOf(user.address)
    await ennead.ve.connect(user).approve(ennead.tokenStaking.address, MAX_UINT)
    await ennead.tokenStaking.connect(user).deposit(amount, user.address)
    // since only 1 deposit bal == shares
    expect(await ennead.tokenStaking.totalAssets()).eq(amount)
    expect(await ennead.tokenStaking.totalSupply()).eq(amount)
    expect(await ennead.rewards.balanceOf(user.address)).eq(amount)
    expect(await ennead.rewards.totalSupply()).eq(amount)
    await ennead.tokenStaking.connect(user).withdraw(amount, user.address, user.address)
    expect(await ennead.ve.balanceOf(user.address)).eq(bal)
  })
  
  it("Must not allow other users to withdraw somebody elses tokens without approval", async function () {
      await ennead.tokenStaking.connect(user).deposit(amount, user.address)
      await expect(ennead.tokenStaking.connect(user2).withdraw(amount, user2.address, user.address)).to.be.reverted
      await expect(ennead.tokenStaking.connect(user2).withdraw(amount, user.address, user.address)).to.be.reverted
      await expect(ennead.tokenStaking.connect(user2).withdraw(amount, user2.address, user2.address)).to.be.reverted
  })

  it("Should record balances properly when transferring", async function () {
    await ennead.tokenStaking.connect(user).transfer(user2.address, amount)
    expect(await ennead.tokenStaking.balanceOf(user.address)).eq(0)
    expect(await ennead.tokenStaking.balanceOf(user2.address)).eq(amount)
    // totalSupply and assets must not change when transferring
    expect(await ennead.tokenStaking.totalAssets()).eq(amount) // only 1 deposit
    expect(await ennead.tokenStaking.totalSupply()).eq(amount)
    expect(await ennead.rewards.balanceOf(user.address)).eq(0)
    expect(await ennead.rewards.balanceOf(user2.address)).eq(amount)
    expect(await ennead.rewards.totalSupply()).eq(amount)
  })

  it("Should allow users to claim notified rewards", async function() {
    let role = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("NOTIFIER_ROLE"))
    await ennead.rewards.connect(ennead.deployer).grantRole(role, ramFaucet.address)
    await ram.connect(ramFaucet).approve(ennead.rewards.address, MAX_UINT)
    await ennead.rewards.connect(ramFaucet).notifyRewardAmount(ram.address, ethers.utils.parseEther("10000"))
    await time.increase(3600)
    expect(await ennead.rewards.earned(ram.address, user2.address)).greaterThan(0)
    expect(await ennead.rewards.earned(ram.address, user.address)).eq(0)
    let bal = await ram.balanceOf(user2.address)
    await ennead.rewards.connect(user2).getReward()
    expect(await ram.balanceOf(user2.address)).greaterThan(bal)
    bal = await ram.balanceOf(user.address)
    await ennead.rewards.connect(user).getReward()
    expect(await ram.balanceOf(user.address)).eq(bal)
  })

  // FeeHandler tests

  it("Should allow FeeHandler to claim bribes on behalf of Booster", async function () {
    await ennead.fees.syncTokenId()
    await expect(ennead.fees.claimBribes(frxEth)).not.to.be.reverted // function was set to public for this test, doesnt matter if there are votes or pending bribes for the pool
  })

  it("Should lock ram bribes to neadRam and send to neadRam stakers", async function () {
    await ram.connect(ramFaucet).transfer(ennead.fees.address, ethers.utils.parseEther("10000"))
    let bal = await ennead.ve.balanceOf(ennead.rewards.address)
    let userBal = await ram.balanceOf(user.address)
    await ennead.fees.connect(user).processBribes("0x1E50482e9185D9DAC418768D14b2F2AC2b4DAF39", user.address)
    expect(await ennead.ve.balanceOf(ennead.rewards.address)).greaterThan(bal)
    expect(await ram.balanceOf(user.address)).greaterThan(userBal)
  })

  it("Should send weth bribes to stakers", async function () {
    await weth.connect(wethFaucet).transfer(ennead.fees.address, ethers.utils.parseEther("1"));
    let bal = await weth.balanceOf(ennead.rewards.address)
    let userBal = await weth.balanceOf(user.address)
    await ennead.fees.connect(user).processBribes("0x1E50482e9185D9DAC418768D14b2F2AC2b4DAF39", user.address)
    expect(await weth.balanceOf(ennead.rewards.address)).greaterThan(bal)
    expect(await weth.balanceOf(user.address)).greaterThan(userBal)
  })
  
  it("Should swap other bribes to weth and send to neadRam stakers", async function () {
    await dei.connect(deiFaucet).transfer(ennead.fees.address, ethers.utils.parseEther("10000"))
    let bal = await weth.balanceOf(ennead.rewards.address)
    let userBal = await weth.balanceOf(user.address)
    await ennead.fees.connect(user).processBribes(lusdDei.address, user.address)
    expect(await weth.balanceOf(ennead.rewards.address)).greaterThan(bal)
    expect(await weth.balanceOf(user.address)).greaterThan(userBal)
  })

  it("Should lock or swap ram performance fees and send to neadRam stakers", async function () {
    await ram.connect(ramFaucet).transfer(ennead.fees.address, ethers.utils.parseEther("10000"))
    await ennead.fees.connect(user).processPerformanceFees(ram.address, user.address)
  })
});
