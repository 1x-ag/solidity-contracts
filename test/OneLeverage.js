// const { expectRevert } = require('openzeppelin-test-helpers');
// const { expect } = require('chai');

const OneLeverage = artifacts.require('OneLeverage');
const HolderOne = artifacts.require('HolderOne');
const Token = artifacts.require('Token');

contract('OneLeverage', function ([_, w1, w2]) {
    describe('OneLeverage', async function () {
        beforeEach(async function () {
            this.token = await Token.new(1000000000);
            this.holder = await HolderOne.new();
            this.one = await OneLeverage.new(
                "1x.ag 2x ETH-DAI",
                "2xETHDAI",
                "0x0000000000000000000000000000000000000000",
                this.token.address,
                5
            );

            await this.token.transfer(w1, 1000000);
            await this.token.transfer(w2, 1000000);
        });

        it('should be ok', async function () {
            await this.token.approve(this.one.address, 1000, { from: w1 });
            await this.one.openPosition(1000, this.holder.address, 0, 0, { from: w1 });
        });
    });
});
