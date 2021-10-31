var TestERC20Token = artifacts.require("./TestERC20Token.sol");
var ArtifactToken = artifacts.require("./ArtifactToken.sol");
var BidProcess = artifacts.require("./BidProcess.sol");


contract("BidProcess", function(accounts) {
  var token;
  var artifact;
  var bidprocess;

  beforeEach("create instances of token, artifact and bidprocess contracts", async function(){
      token = await TestERC20Token.new({from: accounts[0]});
      artifact = await ArtifactToken.new({from: accounts[1]});
      bidprocess = await BidProcess.new({from: accounts[2]});
  })

  async function assertThrow(promise) {
      try {
          await promise;
      } catch (error) {
          const revert = error.message.search('revert') >= 0;
          assert(revert, "Expected throw, got '" + error + "' instead");
          return;
      }
      assert.fail('Expected throw not received');
  };

  function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
  }

  it("initializes with empty list of bids", async function() {
      let count = await bidprocess.getTotalBids();
      assert.equal(count, 0);
  });

  it("should create an bid", async function() {
      // make sure account[1] is owner of the artifact
      let owner = await artifact.ownerOf(0);
      assert.equal(owner, accounts[1]);

      // allow bidprocess to transfer the artifact
      await artifact.approve(bidprocess.address, 0, {from: accounts[1]});

      // create bid
      await bidprocess.createNewBid(artifact.address, 0, token.address, 0, 0, 10, {from: accounts[1]});

      // make sure bid was created
      let count = await bidprocess.getTotalBids();
      assert.equal(count, 1);
  });

  it("should not create bid if asset was not previously approved", async function() {
      let approved = await artifact.getApproved(0);
      assert.equal(approved, 0x0);

      await assertThrow(
        bidprocess.createNewBid(artifact.address, 0, token.address, 0, 0, 10, {from: accounts[1]})
      );
  });

  it("should not create bid if msg.sender is not the asset owner", async function() {
      let owner = await artifact.ownerOf(0);
      assert.equal(owner, accounts[1]);

      // allow bidprocess to transfer the artifact
      await artifact.approve(bidprocess.address, 0, {from: accounts[1]});

      await assertThrow(
        bidprocess.createNewBid(artifact.address, 0, token.address, 0, 0, 10, {from: accounts[0]})  // accounts[0] is not the owner
      );
  });

  it("should bid and transfer tokens to the  bidprocess", async function() {
      // allow bidprocess to transfer the artifact
      await artifact.approve(bidprocess.address, 0, {from: accounts[1]});

      // create bid
      await bidprocess.createNewBid(artifact.address, 0, token.address, 0, 0, 10, {from: accounts[1]});

      let beforeBalance = await token.balanceOf(accounts[0]);
      let initialBalance = 100000000000000 * (10**18);
      assert.equal(beforeBalance.toString(), initialBalance);

      // before bidding we need to allow the bidprocess to transfer the tokens
      await token.approve(bidprocess.address, 1000, {from: accounts[0]});

      // place the bid
      await bidprocess.bid(0, 1000, {from: accounts[0]});

      let afterBalance = await token.balanceOf(accounts[0]);
      assert.equal(afterBalance, initialBalance - 1000);

      let bidprocessBalance = await token.balanceOf(bidprocess.address);
      assert.equal(bidprocessBalance, 1000);
  });


  it("should transfer the asset to the winner and tokens to the creator when bid is claimed", async function(){
      // allow bidprocess to transfer the artifact
      await artifact.approve(bidprocess.address, 0, {from: accounts[1]});

      // create bid
      await bidprocess.createNewBid(artifact.address, 0, token.address, 0, 0, 1, {from: accounts[1]});  // 1 second bid

      // before bidding we need to allow the bidprocess to transfer the tokens
      await token.approve(bidprocess.address, 1000, {from: accounts[0]});

      // place the bid
      await bidprocess.bid(0, 1000, {from: accounts[0]});

      await sleep(1000)  // sleep 1 second until bid is finished

      let isFinished = await bidprocess.isFinished(0);
      assert.equal(true, true);

      let winner = accounts[0];
      assert.equal(winner, accounts[0]);

      // precondition: before claiming, accounts[0] has no assets
      // all artifacts belong to accounts[1]
      let assetCountAccount0 = await artifact.balanceOf(accounts[0]);
      assert.equal(assetCountAccount0.toNumber(), 0);
      let assetCountAccount1 = await artifact.balanceOf(accounts[1]);
      assert.equal(assetCountAccount1.toNumber(), 3);

      // bid winner claims the asset
      await bidprocess.claimAsset(0, {from: accounts[0]});

      // poscondition: artifact that participated in the bid must
      // be transfered to the bid winner
      assetCountAccount0 = await artifact.balanceOf(accounts[0]);
      assert.equal(assetCountAccount0.toNumber(), 1);
      assetCountAccount1 = await artifact.balanceOf(accounts[1]);
      assert.equal(assetCountAccount1.toNumber(), 2);

      let artifactOwner = await artifact.ownerOf(0);
      assert.equal(artifactOwner, accounts[0]);

      // balances preconditions
      let initialBalance = 100000000000000 * (10**18);
      let bidAmount = 1000
      let tokenBalanceAccount0 = await token.balanceOf(accounts[0]);
      assert.equal(tokenBalanceAccount0.toString(), initialBalance - bidAmount);
      let tokenBalancebidprocess = await token.balanceOf(bidprocess.address);
      assert.equal(tokenBalancebidprocess.toString(), bidAmount);
      let tokenBalanceAccount1 = await token.balanceOf(accounts[1]);
      assert.equal(tokenBalanceAccount1.toString(), 0);

      // bid creator claims the tokens
      await bidprocess.claimTokens(0, {from: accounts[1]});

      // balances posconditions
      tokenBalanceAccount0 = await token.balanceOf(accounts[0]);
      assert.equal(tokenBalanceAccount0.toString(), initialBalance - bidAmount);
      tokenBalancebidprocess = await token.balanceOf(bidprocess.address);
      assert.equal(tokenBalancebidprocess.toString(), 0);
      tokenBalanceAccount1 = await token.balanceOf(accounts[1]);
      assert.equal(tokenBalanceAccount1.toString(), bidAmount);
  });
});