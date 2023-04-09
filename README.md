# AZWorlds [![Github Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gha]: https://github.com/threesigmaxyz/foundry-template/actions
[gha-badge]: https://github.com/threesigmaxyz/foundry-template/actions/workflows/ci.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

# Description

AZWorlds is a cross chain finance/skill play to earn game where players compete for the most power and get real rewards in return.
It can be played from any chain using LayerZero's infrastructure, giving access to many assets and defi protocols.

Players buy their characters in a variable rate gradual dutch auction with a target price of 10 USDC per character. 80% of the USDC 
is sent into the military and 20% to the developing team. Players can join the military and receive shares (gold) of the USDC deposits 
over a 1 year interval based on their power.

The power of characters can be increased by fighting bosses on each chain once a day that makes them level up and drop truly random items cryptographically proven using chainlin's VRF2 oracle.

Players can swap items for gold at the marketplace by placing sell and buy orders. They can then equip the bought items for more power.

In the bank, a ERC4626 vault, players can deposit USDC and retrieve gold (shares).

USDC deposited in the bank by either character sales or investors is invested in a protocol decided by governance. This means that
players not only receive rewards based on their power, but also by investing in defi protocols of their choice. Each character gives
a player 1 voting power unit.

Players can also play the UpVsDownGame with gold, betting on the DAI/MATIC price given by a 1 inch protocol price oracle, bringing
full decentralization to AZWorlds. The oracle is flash loan protected by only allowing EOA's to fetch the oracle price.


# About Us
[Three Sigma](https://threesigma.xyz/) is a venture builder firm focused on blockchain engineering, research, and investment. Our mission is to advance the adoption of blockchain technology and contribute towards the healthy development of the Web3 space.

If you are interested in joining our team, please contact us [here](mailto:info@threesigma.xyz).

---

<p align="center">
  <img src="https://threesigma.xyz/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fthree-sigma-labs-research-capital-white.0f8e8f50.png&w=2048&q=75" width="75%" />
</p>
