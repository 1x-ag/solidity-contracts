// const { expectRevert } = require('openzeppelin-test-helpers');
// const { expect } = require('chai');

const OneLeverage = artifacts.require('OneLeverage');
const HolderOne = artifacts.require('HolderOne');

contract('OneLeverage', function ([_, addr1]) {
    describe('OneLeverage', async function () {
        it('should be ok', async function () {
            this.token = await OneLeverage.new(
                "1x.ag 2x ETH-DAI",
                "2xETHDAI",
                "0x0000000000000000000000000000000000000000",
                "0x6B175474E89094C44Da98b954EedeAC495271d0F",
                2
            );
            this.holder = await HolderOne.new();
        });
    });
});
