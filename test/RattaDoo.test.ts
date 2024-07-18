import { ethers } from "hardhat";
import { Signer } from "ethers";
import { expect } from "chai";
import { RattaDoo } from "../typechain-types";

describe("RattaDoo Contract", function () {
  let admin: Signer;
  let player1: Signer;
  let player2: Signer;
  let adminAddress: string;
  let player1Address: string;
  let player2Address: string;
  let contract: RattaDoo;
  const roomFee = BigInt(ethers.parseEther("100"));
  const roomMaxPlayers = BigInt(2);
  const prizePercentage = BigInt(90);

  beforeEach(async function () {
    [admin, player1, player2] = await ethers.getSigners();
    adminAddress = await admin.getAddress();
    player1Address = await player1.getAddress();
    player2Address = await player2.getAddress();

    const RattaDoo = await ethers.getContractFactory("RattaDoo");
    contract = await RattaDoo.deploy(roomFee, roomMaxPlayers, prizePercentage);
    await contract.waitForDeployment();
  });

  it("Should allow a player to enter the default room and select a winner", async function () {
    const balancesOfPlayers = {
      [await player1Address]:
        (await ethers.provider.getBalance(await player1Address)) -
        roomFee,
      [await player2Address]:
        (await ethers.provider.getBalance(await player2Address)) -
        roomFee,
    };

    // Player 1 joins the default room
    await contract.connect(player1).play({ value: roomFee });

    const tx = await (
      await contract.connect(player2).play({ value: roomFee })
    ).wait();

    const winner = (tx?.logs[1] as any).args[0];

    const prizeAmount =
      (BigInt(roomMaxPlayers) * roomFee * prizePercentage) / BigInt(100);

    const winnerBalaneAfter = await ethers.provider.getBalance(winner);

    expect(winnerBalaneAfter).to.approximately(
      balancesOfPlayers[winner] + prizeAmount,
      ethers.parseEther("0.0003")
    );
  });

  it("Should allow creation and participation in a custom room", async function () {
    // Admin creates a custom room
    await contract
      .connect(admin)
      .createRoom(
        roomFee,
        roomMaxPlayers,
        prizePercentage,
        player1Address,
        "Custom Room"
      );

    const balancesOfPlayers = {
      [await player1Address]:
        (await ethers.provider.getBalance(await player1Address)) -
        roomFee,
      [await player2Address]:
        (await ethers.provider.getBalance(await player2Address)) -
        roomFee,
    };

    // Player 1 joins the default room
    await contract.connect(player1).playInCustomRoom(0, { value: roomFee });

    const tx = await (
      await contract.connect(player2).playInCustomRoom(0, { value: roomFee })
    ).wait();

    const winner = (tx?.logs[1] as any).args[0];

    const prizeAmount =
      (BigInt(roomMaxPlayers) * roomFee * prizePercentage) / BigInt(100);

    const winnerBalaneAfter = await ethers.provider.getBalance(winner);

    expect(winnerBalaneAfter).to.approximately(
      balancesOfPlayers[winner] + prizeAmount,
      ethers.parseEther("0.0003")
    );
  });

  it("Should allow admin to claim their pending withdrawals", async function () {
    // Admin creates a custom room
    await contract
      .connect(admin)
      .createRoom(
        roomFee,
        roomMaxPlayers,
        prizePercentage,
        player1Address,
        "Custom Room"
      );

    const balancesOfPlayers = {
      [await player1Address]:
        (await ethers.provider.getBalance(await player1Address)) -
        roomFee,
      [await player2Address]:
        (await ethers.provider.getBalance(await player2Address)) -
        roomFee,
    };

    // Player 1 joins the default room
    await contract.connect(player1).playInCustomRoom(0, { value: roomFee });

    const tx = await (
      await contract.connect(player2).playInCustomRoom(0, { value: roomFee })
    ).wait();

    const winner = (tx?.logs[1] as any).args[0];

    const prizeAmount =
      (BigInt(roomMaxPlayers) * roomFee * prizePercentage) / BigInt(100);

    const winnerBalaneAfter = await ethers.provider.getBalance(winner);

    expect(winnerBalaneAfter).to.approximately(
      balancesOfPlayers[winner] + prizeAmount,
      ethers.parseEther("0.0003")
    );

    const roomOwner = await ethers.provider.getBalance(player1Address);
    await (await contract.connect(player1).claim()).wait();
    const newBalance = await ethers.provider.getBalance(player1Address);

    expect(newBalance).to.be.gt(roomOwner);
  });

  it("Should allow non admin to claim their pending withdrawals from custom game", async function () {
    const balancesOfPlayers = {
      [await player1Address]:
        (await ethers.provider.getBalance(await player1Address)) -
        roomFee,
      [await player2Address]:
        (await ethers.provider.getBalance(await player2Address)) -
        roomFee,
    };
    await contract.connect(player1).play({ value: roomFee });

    const tx = await (
      await contract.connect(player2).play({ value: roomFee })
    ).wait();

    const winner = (tx?.logs[1] as any).args[0];

    const prizeAmount =
      (BigInt(roomMaxPlayers) * roomFee * prizePercentage) / BigInt(100);

    const winnerBalaneAfter = await ethers.provider.getBalance(winner);

    expect(winnerBalaneAfter).to.approximately(
      balancesOfPlayers[winner] + prizeAmount,
      ethers.parseEther("0.0003")
    );
    const adminInitialBalance = await ethers.provider.getBalance(
      await adminAddress
    );
    await (await contract.connect(admin).claim()).wait();
    const newBalance = await ethers.provider.getBalance(
      await adminAddress
    );

    expect(newBalance).to.be.gt(adminInitialBalance);
  });

  it("Should revert if the game entry fee is incorrect", async function () {
    await expect(
      contract.connect(player1).play({ value: ethers.parseEther("0.05") })
    ).to.be.revertedWith("Incorrect game entry fee");
  });

  it("Should revert if non-admin tries to create a room", async function () {
    await expect(
      contract
        .connect(player1)
        .createRoom(
          ethers.parseEther("0.2"),
          3,
          60,
          player1Address,
          "Custom Room"
        )
    ).to.be.revertedWith("Only admin can perform this action");
  });
});
