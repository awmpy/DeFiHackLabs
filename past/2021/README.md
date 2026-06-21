# DeFi Hacks Reproduce - Foundry

## Before 2021 - List of Past DeFi Incidents

68 incidents included.

[20211221 Visor Finance](#20211221-visor-finance---reentrancy)

[20211218 Grim Finance](#20211218-grim-finance---flashloan--reentrancy)

[20211214 Nerve Bridge](#20211214-nerve-bridge---swap-metapool-attack)

[20211130 MonoX Finance](#20211130-monox-finance---price-manipulation)

[20211123 Ploutoz Finance](#20211123-ploutoz---flash-loan)

[20211103 Vesper Finance](#20211103-vesper-finance---uniswap-v3-twap-oracle-manipulation)

[20211027 Cream Finance](#20211027-creamfinance---price-manipulation)

[20211015 Indexed Finance](#20211015-indexed-finance---price-manipulation)

[20210921 Vee Finance](#20210921-vee-finance---low-liquidity-price-manipulation)

[20210916 SushiSwap Miso](#20210916-sushiswap-miso)

[20210915 Nimbus Platform](#20210915-nimbus-platform)

[20210915 NowSwap Platform](#20210915-nowswap-platform)

[20210912 ZABU Finance](#20210912-ZABU-Finance---Deflationary-token-uncompatible)

[20210903 DAO Maker](#20210903-dao-maker---bad-access-controal)

[20210830 Cream Finance](#20210830-cream-finance---flashloan-attack--reentrancy)

[20210829 xToken](#20210829-xtoken---missing-caller-validation)

[20210817 XSURGE](#20210817-xsurge---flashloan-attack--reentrancy)

[20210811 Poly Network](#20210811-poly-network---bridge-getting-around-modifier-through-cross-chain-message)

[20210804 WaultFinance](#20210804-waultfinace---flashloan-price-manipulation)

[20210804 Popsicle](#20210804-popsicle---repeated-reward-claim---logic-flaw)

[20210728 Levyathan Finance](#20210728-levyathan-finance---i-lost-keys-and-minting-ii-vulnerable-emergencywithdraw)

[20210716 PolyBunny](#20210716-polybunny---flashloan-incentive-rewards-exploit)

[20210714 ApeRocket](#20210714-aperocket---flashloan-incentive-rewards-exploit)

[20210710 Chainswap](#20210710-chainswap---bridge-logic-flaw)

[20210702 Chainswap](#20210702-chainswap---bridge-logic-flaw)

[20210628 SafeDollar](#20210628-safedollar---deflationary-token-uncompatible)

[20210625 xWin Finance](#20210625-xwin-finance---subscription-incentive-mechanism)

[20210622 Eleven Finance](#20210622-eleven-finance---doesnt-burn-shares)

[20210607 88mph NFT](#20210607-88mph-nft---access-control)

[20210603 PancakeHunny](#20210603-pancakehunny---incorrect-calculation)

[20210529 Belt Finance](#20210529-belt-finance---vault-share-price-manipulation)

[20210527 JulSwap](#20210527-julswap---flash-loan)

[20210527 BurgerSwap](#20210527-burgerswap---mathematical-flaw--reentrancy)

[20210526 Merlin Labs](#20210526-merlin-labs---reward-calculation-error)

[20210524 AutoShark](#20210524-autoshark---price-oracle-manipulation)

[20210512 xToken](#20210512-xtoken---arbitrary-bancor-mint-path)

[20210519 PancakeBunny](#20210519-pancakebunny---price-oracle-manipulation)

[20210516 bEarn](#20210516-bearn---logic-flaw)

[20210508 Rari Capital](#20210509-raricapital---cross-contract-reentrancy)

[20210508 Value Defi](#20210508-value-defi---cross-contract-reentrancy)

[20210502 Spartan](#20210502-spartan---logic-flaw)

[20210428 Uranium](#20210428-uranium---miscalculation)

[20210308 DODO](#20210308-dodo---flashloan-attack)

[20210305 Paid Network](#20210305-paid-network---private-key-compromised)

[20210227 Furucombo](#20210227-furucombo---delegatecall-exploit)

[20210213 Alpha Finance](#20210213-alpha-finance---debt-share-rounding)

[20210209 Growth DeFi](#20210209-growth-defi---fake-pair-validation)

[20210204 Yearn YDai](#20210204-yearn-ydai---Slippage-proection-absent)

[20210125 Sushi Badger Digg](#20210125-sushi-badger-digg---sandwich-attack)

[20201229 Cover Protocol](#20201229-cover-protocol)

[20201218 Warp Protocol](#20201218-warp-protocol---price-oracle-manipulation)

[20201121 Pickle Finance](#20201121-pickle-finance)

[20201117 Origin Dollar](#20201117-origin-dollar---reentrancy)

[20201114 Value DeFi](#20201114-value-defi---price-oracle-manipulation)

[20201112 Akropolis](#20201112-akropolis---fake-token-reentrancy)

[20201026 Harvest Finance](#20201026-harvest-finance---flashloan-attack)

[20200928 Eminence](#20200928-eminence---bonding-curve-manipulation)

[20200912 bzx](#20200912-bzx---incorrect-transfer)

[20200804 Opyn Protocol](#20200804-opyn-protocol---msgValue-in-loop)

[20200628 Balancer Protocol](#20200628-balancer-protocol---token-incompatible)

[20200618 Bancor Protocol](#20200618-bancor-protocol---access-control)

[20200419 LendfMe](#20200419-lendfme---erc777-reentrancy)

[20200418 UniSwapV1](#20200418-uniswapv1---erc777-reentrancy)

[20181007 SpankChain](#20181007-spankchain---reentrancy)

[20180424 SmartMesh](#20180424-smartmesh---overflow)

[20180422 Beauty Chain](#20180422-beauty-chain---integer-overflow)

[20171106 Parity - 'Accidentally Killed It'](#20171106-parity---accidentally-killed-it)

[20170719 Parity Multisig](#20170719-parity-multisig---delegatecall-to-unprotected-initwallet)

### 20210829 xToken - Missing Caller Validation

#### Lost: $4.5 million

```sh
forge test --contracts ./src/test/2021-08/xToken_exp.sol --match-contract XTokenExploitTest -vv
```

[xToken_exp.sol](../../src/test/2021-08/xToken_exp.sol)

---

### 20210512 xToken - Arbitrary Bancor Mint Path

#### Lost: $24 million

```sh
forge test --contracts ./src/test/2021-05/xToken_exp.sol --match-contract XTokenMayExploitTest -vv
```

[xToken_exp.sol](../../src/test/2021-05/xToken_exp.sol)

---

### 20210213 Alpha Finance - Debt Share Rounding

#### Lost: $37.5 million

```sh
forge test --contracts ./src/test/2021-02/AlphaFinance_exp.sol --match-contract AlphaFinanceExploitTest -vv
```

[AlphaFinance_exp.sol](../../src/test/2021-02/AlphaFinance_exp.sol)

---

### 20210209 Growth DeFi - Fake Pair Validation

#### Lost: $1.3 million

```sh
forge test --contracts ./src/test/2021-02/GrowthDeFi_exp.sol --match-contract GrowthDeFiExploitTest -vv
```

[GrowthDeFi_exp.sol](../../src/test/2021-02/GrowthDeFi_exp.sol)

---

### 20211221 Visor Finance - Reentrancy

#### Lost: $8.2 million

Testing

```sh
forge test --contracts ./src/test/2021-12/Visor_exp.sol -vv
```

#### Contract

[Visor_exp.sol](../../src/test/2021-12/Visor_exp.sol)

#### Link reference

https://beosin.medium.com/two-vulnerabilities-in-one-function-the-analysis-of-visor-finance-exploit-a15735e2492

https://twitter.com/GammaStrategies/status/1473306777131405314

https://etherscan.io/tx/0x69272d8c84d67d1da2f6425b339192fa472898dce936f24818fda415c1c1ff3f

---

### 20211218 Grim Finance - Flashloan & Reentrancy

#### Lost: $30 million

Testing

```sh
forge test --contracts ./src/test/2021-12/Grim_exp.sol -vv
```

#### Contract

[Grim_exp.sol](../../src/test/2021-12/Grim_exp.sol)

#### Link reference

https://cointelegraph.com/news/defi-protocol-grim-finance-lost-30m-in-5x-reentrancy-hack

https://rekt.news/grim-finance-rekt/

https://ftmscan.com/tx/0x19315e5b150d0a83e797203bb9c957ec1fa8a6f404f4f761d970cb29a74a5dd6

---

### 20211214 Nerve Bridge - Swap Metapool Attack

#### Lost: 900 BNB

Testing

```sh
forge test --contracts ./src/test/2021-12/NerveBridge_exp.sol -vv
```

#### Contract

[NerveBridge_exp.sol](../../src/test/2021-12/NerveBridge_exp.sol)

#### Link reference

https://blocksecteam.medium.com/the-analysis-of-nerve-bridge-security-incident-ead361a21025

---

### 20211130 MonoX Finance - Price Manipulation

#### Lost: $31 million

Testing

```sh
forge test --contracts ./src/test/2021-11/Mono_exp.sol -vv
```

#### Contract

[Mono_exp.sol](../../src/test/2021-11/Mono_exp.sol)

#### Link reference

https://slowmist.medium.com/detailed-analysis-of-the-31-million-monox-protocol-hack-574d8c44a9c8

https://knownseclab.com/news/61a986811992da0067558749

https://www.tuoniaox.com/news/p-521076.html

https://polygonscan.com/tx/0x5a03b9c03eedcb9ec6e70c6841eaa4976a732d050a6218969e39483bb3004d5d

https://etherscan.io/tx/0x9f14d093a2349de08f02fc0fb018dadb449351d0cdb7d0738ff69cc6fef5f299

---

### 20211123 Ploutoz - Flash Loan

#### Lost: 365K

Testing
```sh
forge test --contracts ./src/test/2021-11/Ploutoz_exp.sol -vvv --evm-version shanghai
```

#### Contract

[Ploutoz_exp.sol](../../src/test/2021-11/Ploutoz_exp.sol)

### Link reference

https://x.com/peckshield/status/1463113809111896065

---

### 20211103 Vesper Finance - Uniswap V3 TWAP Oracle Manipulation

#### Lost: ~$3.4M

```sh
forge test --contracts ./src/test/2021-11/VesperFinance_exp.sol --match-contract VesperFinanceExploitTest -vv
```

#### Contract

[VesperFinance_exp.sol](../../src/test/2021-11/VesperFinance_exp.sol)

#### Link reference

https://etherscan.io/tx/0x89d0ae4dc1743598a540c4e33917efdce24338723b0fabf34813b79cb0ecf4c5

https://etherscan.io/tx/0x8527fea51233974a431c92c4d3c58dee118b05a3140a04e0f95147df9faf8092

---

### 20211027 CreamFinance - Price Manipulation

#### Lost: $130M

Testing

```sh
 forge test --contracts ./src/test/2021-10/Cream_2_exp.sol -vvv
```

#### Contract

[Cream_2_exp.sol](../../src/test/2021-10/Cream_2_exp.sol)

#### Link reference

https://medium.com/immunefi/hack-analysis-cream-finance-oct-2021-fc222d913fc5

---

### 20211015 Indexed Finance - Price Manipulation

#### Lost: $16M

Testing

```sh
forge test --contracts src/test/2021-10/IndexedFinance_exp.sol -vv
```

#### Contract

[IndexedFinance_exp.sol](../../src/test/2021-10/IndexedFinance_exp.sol)

#### Link reference

https://blocksecteam.medium.com/the-analysis-of-indexed-finance-security-incident-8a62b9799836

---

### 20210921 Vee Finance - Low Liquidity Price Manipulation

#### Lost: ~$34M

```sh
forge test --contracts ./src/test/2021-09/VeeFinance_exp.sol --match-contract VeeFinanceExploitTest -vv
```

#### Contract

[VeeFinance_exp.sol](../../src/test/2021-09/VeeFinance_exp.sol)

#### Link reference

https://snowtrace.io/tx/0x3f7159110d3204363821fb6bc4490d4f9ca76e8a6869462474f8b0336c7eb582

---

### 20210916 SushiSwap Miso - Insufficient validation

#### Lost: All funds returned

Testing

```sh
forge test --contracts ./src/test/2021-09/Sushimiso_exp.sol -vv
```

#### Contract

[Sushimiso_exp.sol](../../src/test/2021-09/Sushimiso_exp.sol)

#### Link reference

https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong

https://etherscan.io/tx/0x78d6355703507f88f2090eb780d245b0ab26bf470eabdb004761cedf3b1cda44

---

### 20210915 Nimbus Platform - Incorrect calculation

#### Lost: 1.45 ETH

Testing

```sh
forge test --contracts ./src/test/2021-09/Nimbus_exp.sol -vv
```

#### Contract

[Nimbus_exp.sol](../../src/test/2021-09/Nimbus_exp.sol)

#### Link reference

https://twitter.com/BlockSecTeam/status/1438100688215560192

---

### 20210915 NowSwap Platform - Incorrect calculation

#### Lost: 158.28 WETH and 535,706 USDT

Testing

```sh
forge test --contracts ./src/test/2021-09/NowSwap_exp.sol -vv
```

#### Contract

[NowSwap_exp.sol](../../src/test/2021-09/NowSwap_exp.sol)

#### Link reference

https://twitter.com/BlockSecTeam/status/1438100688215560192

---

### 20210912 ZABU Finance - Deflationary token uncompatible

Testing

```sh
forge test --contracts src/test/2021-09/ZABU_exp.sol -vvv
```

#### Contract

[ZABU_exp.sol](../../src/test/2021-09/ZABU_exp.sol)

### Link reference

https://slowmist.medium.com/brief-analysis-of-zabu-finance-being-hacked-44243919ea29

---

### 20210903 DAO Maker - Bad Access Controal

#### Lost: $4 million

Testing

```sh
forge test --contracts ./src/test/2021-09/DaoMaker_exp.sol -vv
```

#### Contract

[DaoMaker_exp.sol](../../src/test/2021-09/DaoMaker_exp.sol)

#### Link reference

https://twitter.com/Mudit__Gupta/status/1434059922774237185

https://etherscan.io/tx/0xd5e2edd6089dcf5dca78c0ccbdf659acedab173a8ab3cb65720e35b640c0af7c

---

### 20210830 Cream Finance - Flashloan Attack + Reentrancy

#### Lost: $18 million

Testing

```sh
forge test --contracts ./src/test/2021-08/Cream_exp.sol -vv
```

#### Contract

[Cream_exp.sol](../../src/test/2021-08/Cream_exp.sol)

#### Link reference

https://twitter.com/peckshield/status/1432249600002478081

https://twitter.com/creamdotfinance/status/1432249773575208964

https://etherscan.io/tx/0xa9a1b8ea288eb9ad315088f17f7c7386b9989c95b4d13c81b69d5ddad7ffe61e

---

### 20210817 XSURGE - Flashloan Attack + Reentrancy

#### Lost: $5 million

Testing

```sh
forge test --contracts ./src/test/2021-08/XSURGE_exp.sol -vv
```

#### Contract

[XSURGE_exp.sol](../../src/test/2021-08/XSURGE_exp.sol)

#### Link reference

https://beosin.medium.com/a-sweet-blow-fb0a5e08657d

https://medium.com/@Knownsec_Blockchain_Lab/knownsec-blockchain-lab-comprehensive-analysis-of-xsurge-attacks-c83d238fbc55

https://bscscan.com/tx/0x8c93d6e5d6b3ec7478b4195123a696dbc82a3441be090e048fe4b33a242ef09d

---

### 20210811 Poly Network - Bridge, getting around modifier through cross-chain message

#### Lost: $611 million

Testing

```sh
forge test --contracts ./src/test/2021-08/PolyNetwork_exp.sol -vv
```

#### Contract

[PolyNetwork_exp.sol](../../src/test/2021-08/PolyNetwork_exp.sol)

#### Link reference

https://rekt.news/polynetwork-rekt/

https://slowmist.medium.com/the-root-cause-of-poly-network-being-hacked-ec2ee1b0c68f

https://etherscan.io/tx/0xb1f70464bd95b774c6ce60fc706eb5f9e35cb5f06e6cfe7c17dcda46ffd59581/advanced

https://github.com/polynetwork/eth-contracts/tree/d16252b2b857eecf8e558bd3e1f3bb14cff30e9b

https://www.breadcrumbs.app/reports/671

#### FIX

One of the biggest design lessons that people need to take away from this is: if you have cross-chain relay contracts like this, MAKE SURE THAT THEY CAN'T BE USED TO CALL SPECIAL CONTRACTS. The EthCrossDomainManager shouldn't have owned the EthCrossDomainData contract.

---

### 20210804 WaultFinace - FlashLoan price manipulation

#### Lost: 390 ETH

Testing

```sh
forge test --contracts ./src/test/2021-08/WaultFinance_exp.sol -vvv
```

#### Contract

[WaultFinance_exp.sol](../../src/test/2021-08/WaultFinance_exp.sol)

#### Link reference

https://medium.com/@Knownsec_Blockchain_Lab/wault-finance-flash-loan-security-incident-analysis-368a2e1ebb5b

https://inspexco.medium.com/wault-finance-incident-analysis-wex-price-manipulation-using-wusdmaster-contract-c344be3ed376

---

### 20210804 Popsicle - Repeated Reward Claim - Logic Flaw

#### Lost: 20M USD

Testing

```sh
forge test --contracts ./src/test/2021-08/Popsicle_exp.sol -vvv
```

#### Contract

[Popsicle_exp.sol](../../src/test/2021-08/Popsicle_exp.sol)

#### Link reference

https://blocksecteam.medium.com/the-analysis-of-the-popsicle-finance-security-incident-9d9d5a3045c1

---

### 20210728 Levyathan Finance - (I) Lost keys and minting (II) Vulnerable emergencyWithdraw

#### Lost: $1.5 million

Testing

```sh
forge test --contracts ./src/test/2021-07/Levyathan_exp.sol -vv
```

#### Contract

[Levyathan_exp.sol](../../src/test/2021-07/Levyathan_exp.sol)

#### Link reference

https://levyathan-index.medium.com/post-mortem-levyathan-c3ff7f9a6f65

---

### 20210716 PolyBunny - Flashloan Incentive Rewards Exploit

#### Lost: ~$2.4M

```sh
forge test --contracts ./src/test/2021-07/PolyBunny_exp.sol --match-contract PolyBunnyExploitTest -vv
```

#### Contract

[PolyBunny_exp.sol](../../src/test/2021-07/PolyBunny_exp.sol)

#### Link reference

https://polygonscan.com/tx/0x25e5d9ea359be7fc50358d18c2b6d429d27620fe665a99ba7ad0ea460e50ae55

---

### 20210714 ApeRocket - Flashloan Incentive Rewards Exploit

#### Lost: ~$1.26M

```sh
forge test --contracts ./src/test/2021-07/ApeRocket_exp.sol --match-contract ApeRocketExploitTest -vv
```

#### Contract

[ApeRocket_exp.sol](../../src/test/2021-07/ApeRocket_exp.sol)

#### Link reference

https://bscscan.com/tx/0x701a308fba23f9b328d2cdb6c7b245f6c3063a510e0d5bc21d2477c9084f93e0

---

### 20210710 Chainswap - Bridge, logic flaw

#### Lost: $4.4 million

Testing

```sh
forge test --contracts ./src/test/2021-07/Chainswap_exp2.sol -vv
```

#### Contract

[Chainswap_exp2.sol](../../src/test/2021-07/Chainswap_exp2.sol)

#### Link reference

https://twitter.com/real_n3o/status/1414071223940571139

https://rekt.news/chainswap-rekt/

https://chain-swap.medium.com/chainswap-exploit-11-july-2021-post-mortem-6e4e346e5a32

---

### 20210702 Chainswap - Bridge, logic flaw

#### Lost: $.8 million

Testing

```sh
forge test --contracts ./src/test/2021-07/Chainswap_exp1.sol -vv
```

#### Contract

[Chainswap_exp1.sol](../../src/test/2021-07/Chainswap_exp1.sol)

#### Link reference

https://chain-swap.medium.com/chainswap-post-mortem-and-compensation-plan-90cad50898ab

---

### 20210628 SafeDollar - Deflationary token uncompatible

### Lost: $.2 million

Testing

```sh
forge test --contracts src/test/2021-06/SafeDollar_exp.sol -vvv
```

#### Contract

[SafeDollar_exp.sol](../../src/test/2021-06/SafeDollar_exp.sol)

#### Link reference

https://twitter.com/peckshield/status/1409443556251430918

---

### 20210625 xWin Finance - subscription-incentive-mechanism

### Lost: ~$300k

Testing

```sh
forge test --contracts src/test/2021-06/xWin_exp.sol -vvv
```

#### Contract

[xWin_exp.sol](../../src/test/2021-06/xWin_exp.sol)

#### Link reference

https://peckshield.medium.com/xwin-finance-incident-root-cause-analysis-71d0820e6bc1

---

### 20210622 Eleven Finance - Doesn’t burn shares

Testing

```sh
forge test --contracts ./src/test/2021-06/Eleven_exp.sol -vv
```

#### Contract

[Eleven.sol](../../src/test/2021-06/Eleven_exp.sol)

#### Link reference

https://peckshield.medium.com/eleven-finance-incident-root-cause-analysis-123b5675fa76

https://bscscan.com/tx/0xeaaa8f4d33b1035a790f0d7c4eb6e38db7d6d3b580e0bbc9ba39a9d6b80dd250

---

### 20210607 88mph NFT - Access control

Testing

```sh
forge test --contracts ./src/test/2021-06/88mph_exp.sol -vv
```

#### Contract

[88mph_exp.sol](../../src/test/2021-06/88mph_exp.sol)

#### Link reference

https://medium.com/immunefi/88mph-function-initialization-bug-fix-postmortem-c3a2282894d3

---

### 20210603 PancakeHunny - Incorrect calculation

Testing

```sh
forge test --contracts ./src/test/2021-06/PancakeHunny_exp.sol -vv
```

#### Contract

[PancakeHunny_exp.sol](../../src/test/2021-06/PancakeHunny_exp.sol)

#### Link reference

https://medium.com/hunnyfinance/pancakehunny-post-mortem-analysis-de78967401d8

https://bscscan.com/tx/0x765de8357994a206bb90af57dcf427f48a2021f2f28ca81f2c00bc3b9842be8e

---

### 20210529 Belt Finance - Vault Share Price Manipulation

#### Lost: ~$6.3M

```sh
forge test --contracts ./src/test/2021-05/BeltFinance_exp.sol --match-contract BeltFinanceExploitTest -vv
```

#### Contract

[BeltFinance_exp.sol](../../src/test/2021-05/BeltFinance_exp.sol)

#### Link reference

https://bscscan.com/tx/0x50b0c05dd326022cae774623e5db17d8edbc41b4f064a3bcae105f69492ceadc

---

### 20210527 JulSwap - Flash Loan

### Lost: 1.5M

```sh
forge test --contracts ./src/test/2021-05/JulSwap_exp.sol -vvv --evm-version shanghai
```

#### Contract

[JulSwap_exp.sol](../../src/test/2021-05/JulSwap_exp.sol)

### Link reference

https://x.com/tg_cryptos/status/1398090345368408064

---

### 20210527 BurgerSwap - Mathematical flaw + Reentrancy

Testing

```sh
forge test --contracts src/test/2021-05/BurgerSwap_exp.sol -vv
```

#### Contract

[BurgerSwap_exp.sol](../../src/test/2021-05/BurgerSwap_exp.sol)

#### Link reference

https://twitter.com/Mudit__Gupta/status/1398156036574306304

---

### 20210526 Merlin Labs - Reward Calculation Error

#### Lost: ~$550K

```sh
forge test --contracts ./src/test/2021-05/Merlin_exp.sol --match-contract MerlinExploitTest -vv
```

#### Contract

[Merlin_exp.sol](../../src/test/2021-05/Merlin_exp.sol)

#### Link reference

https://bscscan.com/tx/0x31fdf621f60684579de00f30b33fa051c19f1fd45d891c817e2a3888a9b75726

---

### 20210524 AutoShark - Price Oracle Manipulation

#### Lost: $745K

```sh
forge test --contracts ./src/test/2021-05/AutoShark_exp.sol --match-contract AutoSharkExploitTest -vv
```

#### Contract

[AutoShark_exp.sol](../../src/test/2021-05/AutoShark_exp.sol)

#### Link reference

https://bscscan.com/tx/0xfbe65ad3eed6b28d59bf6043debf1166d3420d214020ef54f12d2e0583a66f13

---

### 20210519 PancakeBunny - Price Oracle Manipulation

Testing

```sh
forge test --contracts ./src/test/2021-05/PancakeBunny_exp.sol -vv
```

#### Contract

[PancakeBunny_exp.sol](../../src/test/2021-05/PancakeBunny_exp.sol)

#### Link reference

https://rekt.news/pancakebunny-rekt/

https://bscscan.com/tx/0x897c2de73dd55d7701e1b69ffb3a17b0f4801ced88b0c75fe1551c5fcce6a979

---

### 20210516 bEarn - Logic Flaw

### Lost: 11M

```sh
forge test --contracts ./src/test/2021-05/bEarn_exp.sol -vvv --evm-version shanghai
```

#### Contract

[bEarn_exp.sol](../../src/test/2021-05/bEarn_exp.sol)

### Link reference

https://bearndao.medium.com/bvaults-busd-alpaca-strategy-exploit-post-mortem-and-bearn-s-compensation-plan-b0b38c3b5540

---

### 20210509 RariCapital - Cross Contract Reentrancy

Testing

```sh
forge test --contracts ./src/test/2021-05/RariCapital_exp.sol -vv
```

#### Contract

[RariCapital_exp.sol](../../src/test/2021-05/RariCapital_exp.sol)

#### Link reference

https://rekt.news/rari-capital-rekt/

https://etherscan.com/tx/0x171072422efb5cd461546bfe986017d9b5aa427ff1c07ebe8acc064b13a7b7be

---

### 20210508 Value Defi - Cross Contract Reentrancy

Testing

```sh
forge test --contracts ./src/test/2021-05/ValueDefi_exp.sol -vv
```

#### Contract

[ValueDefi_exp.sol](../../src/test/2021-05/ValueDefi_exp.sol)

#### Link reference

https://rekt.news/rari-capital-rekt/

https://bscscan.com/tx/0xa00def91954ba9f1a1320ef582420d41ca886d417d996362bf3ac3fe2bfb9006

---

### 20210502 Spartan - Logic Flaw

#### Lost: $30.5M

Testing

```sh
forge test --contracts src/test/2021-05/Spartan_exp.sol -vv
```

#### Contract

[Spartan_exp.sol](../../src/test/2021-05/Spartan_exp.sol)

#### Link reference

https://rekt.news/spartan-rekt/

---

### 20210428 Uranium - Miscalculation

#### Lost: $50 million

Testing

```sh
forge test --contracts ./src/test/2021-04/Uranium_exp.sol -vv
```

#### Contract

[Uranium_exp.sol](../../src/test/2021-04/Uranium_exp.sol)

#### Link reference

https://twitter.com/FrankResearcher/status/1387347025742557186

https://bscscan.com/tx/0x5a504fe72ef7fc76dfeb4d979e533af4e23fe37e90b5516186d5787893c37991

---

### 20200912 bzx - Incorrect transfer

### Lost: 

```sh
forge test --contracts ./src/test/2020-09/bzx_exp.sol -vvv
```
#### Contract

[bzx_exp.sol](../../src/test/2020-09/bzx_exp.sol)

### Link reference

https://twitter.com/0x000000000marc/status/1305354469354303488

---

### 20180424 SmartMesh - Overflow

### Lost: 140M

```sh
forge test --contracts ./src/test/2018-04/SmartMesh_exp.sol -vvv
```
#### Contract

[SmartMesh_exp.sol](../../src/test/2018-04/SmartMesh_exp.sol)

### Link reference

https://cryptojobslist.com/blog/two-vulnerable-erc20-contracts-deep-dive-beautychain-smartmesh

---

### 20210308 DODO - Flashloan Attack

#### Lost: $700,000

Testing

```sh
forge test --contracts ./src/test/2021-03/dodo_flashloan_exp.sol -vv
```

#### Contract

[dodo_flashloan_exp.sol](../../src/test/2021-03/dodo_flashloan_exp.sol)

#### Link reference

https://blog.dodoex.io/dodo-pool-incident-postmortem-with-a-little-help-from-our-friends-327e66872d42

https://halborn.com/explained-the-dodo-dex-hack-march-2021/

https://etherscan.io/tx/0x395675b56370a9f5fe8b32badfa80043f5291443bd6c8273900476880fb5221e

---

### 20210305 Paid Network - Private key compromised

#### Lost: $3 million

Testing

```sh
forge test --contracts ./src/test/2021-03/PAID_exp.sol -vv
```

#### Contract

[PAID_exp.sol](../../src/test/2021-03/PAID_exp.sol)

#### Link reference

https://paidnetwork.medium.com/paid-network-attack-postmortem-march-7-2021-9e4c0fef0e07

https://etherscan.io/tx/0x4bb10927ea7afc2336033574b74ebd6f73ef35ac0db1bb96229627c9d77555a0

---

### 20210227 Furucombo - Delegatecall Exploit

#### Lost: $14 million

```sh
forge test --contracts ./src/test/2021-02/Furucombo_exp.sol --match-contract FurucomboExploitTest -vv
```

#### Contract

[Furucombo_exp.sol](../../src/test/2021-02/Furucombo_exp.sol)

#### Link reference

https://etherscan.io/tx/0x8bf64bd802d039d03c63bf3614afc042f345e158ea0814c74be4b5b14436afb9

---

### 20210204 Yearn YDai - Slippage proection absent

#### Lost: 11 Million $

Testing

```sh
forge test --contracts ./src/test/2021-02/Yearn_ydai_exp.sol -vv
```

#### Contract

[Yearn_ydai.sol](../../src/test/2021-02/Yearn_ydai_exp.sol)

#### Link reference

https://github.com/yearn/yearn-security/blob/master/disclosures/2021-02-04.md

https://etherscan.io/tx/0x59faab5a1911618064f1ffa1e4649d85c99cfd9f0d64dcebbc1af7d7630da98b

---

### 20210125 Sushi Badger Digg - Sandwich attack

#### Lost: 81.68 ETH

Testing

```sh
forge test --contracts src/test/2021-01/Sushi_Badger_Digg_exp.sol -vvvv
```

#### Contract

[Sushi-Badger_Digg.exp.sol](../../src/test/2021-01/Sushi_Badger_Digg_exp.sol)

#### Link reference

https://cmichel.io/replaying-ethereum-hacks-sushiswap-badger-dao-digg/

---

### 20201229 Cover Protocol - Incorrect calculation via cached data

Testing

```sh
forge test --contracts ./src/test/2020-12/Cover_exp.sol -vv
```

#### Contract

[Cover_exp.sol](../../src/test/2020-12/Cover_exp.sol)

#### Link reference

https://mudit.blog/cover-protocol-hack-analysis-tokens-minted-exploit/

https://slowmist.medium.com/a-brief-analysis-of-the-cover-protocol-hacked-event-700d747b309c

---

### 20201218 Warp Protocol - Price Oracle Manipulation

#### Lost: $7.8 million

```sh
forge test --contracts ./src/test/2020-12 --match-contract WarpFinanceExploitTest -vv
```

#### Contract

[WarpFinance_exp.sol](../../src/test/2020-12/WarpFinance_exp.sol)

#### Link reference

https://etherscan.io/tx/0x8bb8dc5c7c830bac85fa48acad2505e9300a91c3ff239c9517d0cae33b595090

---

### 20201121 Pickle Finance - Insufficient validation

#### Lost: $20 million

Testing

```sh
forge test --contracts ./src/test/2020-11/Pickle_exp.sol -vv
```

#### Contract

[Pickle_exp.sol](../../src/test/2020-11/Pickle_exp.sol)

#### Link reference

https://github.com/banteg/evil-jar

https://etherscan.io/tx/0xe72d4e7ba9b5af0cf2a8cfb1e30fd9f388df0ab3da79790be842bfbed11087b0

---

### 20201117 Origin Dollar - Reentrancy

#### Lost: $8 million

```sh
forge test --contracts ./src/test/2020-11 --match-contract OriginDollarExploitTest -vv
```

#### Contract

[OriginDollar_exp.sol](../../src/test/2020-11/OriginDollar_exp.sol)

#### Link reference

https://etherscan.io/tx/0xe1c76241dda7c5fcf1988454c621142495640e708e3f8377982f55f8cf2a8401

---

### 20201114 Value DeFi - Price Oracle Manipulation

#### Lost: $7 million

```sh
forge test --contracts ./src/test/2020-11 --match-contract ValueDeFiExploitTest -vv
```

#### Contract

[ValueDeFi_exp.sol](../../src/test/2020-11/ValueDeFi_exp.sol)

#### Link reference

https://etherscan.io/tx/0x46a03488247425f845e444b9c10b52ba3c14927c687d38287c0faddc7471150a

---

### 20201112 Akropolis - Fake Token Reentrancy

#### Lost: $2 million

```sh
forge test --contracts ./src/test/2020-11 --match-contract AkropolisExploitTest -vv
```

#### Contract

[Akropolis_exp.sol](../../src/test/2020-11/Akropolis_exp.sol)

#### Link reference

https://etherscan.io/tx/0x270836213a621d9f43159439065ddeb54cb9a69fec07fbb63d7f22edd9be5103

---

### 20201026 Harvest Finance - Flashloan Attack

#### Lost: $33.8 million

Testing

```sh
forge test --contracts ./src/test/2020-10/HarvestFinance_exp.sol -vv

```

#### Contract

[HarvestFinance_exp.sol](../../src/test/2020-10/HarvestFinance_exp.sol)

#### Link reference

https://rekt.news/harvest-finance-rekt/

https://etherscan.io/tx/0x35f8d2f572fceaac9288e5d462117850ef2694786992a8c3f6d02612277b0877

---

### 20200928 Eminence - Bonding Curve Manipulation

#### Lost: $15 million

```sh
forge test --contracts ./src/test/2020-09 --match-contract EminenceExploitTest -vv
```

#### Contract

[Eminence_exp.sol](../../src/test/2020-09/Eminence_exp.sol)

#### Link reference

https://etherscan.io/tx/0x3503253131644dd9f52802d071de74e456570374d586ddd640159cf6fb9b8ad8

---

### 20200804 Opyn Protocol - msgValue in loop

Testing

```sh
forge test --contracts ./src/test/2020-08/Opyn_exp.sol -vv
```

#### Contract

[Opyn.exp.sol](../../src/test/2020-08/Opyn_exp.sol)

#### Link reference

https://medium.com/opyn/opyn-eth-put-exploit-post-mortem-1a009e3347a8

https://etherscan.io/tx/0x56de6c4bd906ee0c067a332e64966db8b1e866c7965c044163a503de6ee6552a

---

### 20200628 Balancer Protocol - Token Incompatible

Testing

```sh
forge test --contracts ./src/test/2020-06/Balancer_20200628_exp.sol -vv
```

#### Contract

[Balancer_20200628_exp.sol](../../src/test/2020-06/Balancer_20200628_exp.sol)

#### Link reference

https://slowmist.medium.com/detailed-analysis-of-balancer-hack-de8bd86020de

https://etherscan.io/tx/0x013be97768b702fe8eccef1a40544d5ecb3c1961ad5f87fee4d16fdc08c78106

---

### 20200618 Bancor Protocol - Access Control

Testing

```sh
forge test --contracts ./src/test/2020-06/Bancor_exp.sol -vv
```

#### Contract

[Bancor_exp.sol](../../src/test/2020-06/Bancor_exp.sol)

#### Link reference

https://blog.bancor.network/bancors-response-to-today-s-smart-contract-vulnerability-dc888c589fe4

https://etherscan.io/address/0x5f58058c0ec971492166763c8c22632b583f667f

---

### 20200419 LendfMe - ERC777 Reentrancy

#### Lost: $25,000,000

Testing

```sh
forge test --contracts ./src/test/2020-04/LendfMe_exp.sol -vv
```

#### Contract

[LendfMe_exp](../../src/test/2020-04/LendfMe_exp.sol)

#### Link reference

https://peckshield.medium.com/uniswap-lendf-me-hacks-root-cause-and-loss-analysis-50f3263dcc09

---

### 20200418 UniSwapV1 - ERC777 Reentrancy

#### Lost: $220,000

Testing

```sh
forge test --contracts ./src/test/2020-04/uniswap-erc777.sol -vv
```

#### Contract

[uniswap-erc777.sol](../../src/test/2020-04/uniswap-erc777.sol)

#### Link reference

https://blog.blockmagnates.com/detailed-explanation-of-uniswaps-erc777-re-entry-risk-8fa5b3738e08

---

### 20181007 SpankChain - Reentrancy

### Lost: 155 $ETH


```sh
forge test --contracts ./src/test/2018-10/SpankChain_exp.sol -vvv
```
#### Contract
[SpankChain_exp.sol](../../src/test/2018-10/SpankChain_exp.sol)
### Link reference

https://app.blocksec.com/explorer/tx/eth/0x21e9d20b57f6ae60dac23466c8395d47f42dc24628e5a31f224567a2b4effa88

---

### 20180422 Beauty Chain - Integer Overflow

#### Lost: $900 million

Testing

```sh
forge test --contracts ./src/test/2018-04/BEC_exp.sol -vv
```

#### Contract

[BEC_exp.sol](../../src/test/2018-04/BEC_exp.sol)

#### Link reference

https://etherscan.io/tx/0xad89ff16fd1ebe3a0a7cf4ed282302c06626c1af33221ebe0d3a470aba4a660f

https://etherscan.io/address/0xc5d105e63711398af9bbff092d4b6769c82f793d#code

---

### 20171106 Parity - 'Accidentally Killed It'

#### Lost: 514k ETH

Testing

```sh
forge test --contracts ./src/test/2017-11/Parity_kill_exp.sol -vvvv
```

#### Contract

[Parity_kill.sol](../../src/test/2017-11/Parity_kill_exp.sol)

#### Link reference

https://elementus.io/blog/which-icos-are-affected-by-the-parity-wallet-bug/

https://etherscan.io/tx/0x05f71e1b2cb4f03e547739db15d080fd30c989eda04d37ce6264c5686e0722c9

https://etherscan.io/tx/0x47f7cff7a5e671884629c93b368cb18f58a993f4b19c2a53a8662e3f1482f690

---

### 20170719 Parity Multisig - delegatecall to unprotected initWallet

#### Lost: 153,037 ETH (~$30M)

Testing

```sh
forge test --contracts ./src/test/2017-07/Parity_first_hack_exp.sol -vv
```

#### Contract

[Parity_first_hack_exp.sol](../../src/test/2017-07/Parity_first_hack_exp.sol)

#### Link reference

https://www.openzeppelin.com/news/on-the-parity-wallet-multisig-hack-405a8c12e8f7

https://haseebq.com/a-hacker-stole-31m-of-ether/

https://etherscan.io/tx/0x9dbf0326a03a2a3719c27be4fa69aacc9857fd231a8d9dcaede4bb083def75ec

https://etherscan.io/tx/0xeef10fc5170f669b86c4cd0444882a96087221325f8bf2f55d6188633aa7be7c
