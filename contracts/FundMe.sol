// SPDX-License-Identifier: MIT

// pragma
pragma solidity ^0.8.0;
// imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// errors

// interfaces

// contracts
/** @title A contract for crowd funding
 * @author marcinek.eth
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
  // type declarations
  using PriceConverter for uint256;

  // state variables
  mapping(address => uint256) public s_addressToAmountFunded; // nazwy zmiennych z s_ od storage variable (kosztowne). Memory, immutable oraz constant dużo tańsze ! Aby nie zostawiać brzydko nazwanych zmiennych możemy je zamienić na private a do interakcji z Nimi użyć publicznych funkcji o wygodnych nazwach, które będą je zwracać.
  address[] public s_funders;
  address public s_owner;
  AggregatorV3Interface public s_priceFeed;

  // constructor
  constructor(address priceFeed) {
    s_priceFeed = AggregatorV3Interface(priceFeed);
    s_owner = msg.sender;
  }

  // functions
  /**
   * @notice This function funds this contract
   */
  function fund() public payable {
    uint256 minimumUSD = 50 * 10 ** 18;
    require(
      msg.value.getConversionRate(s_priceFeed) >= minimumUSD,
      "You need to spend more ETH!"
    ); // warto dla zaoszczędzenia gas zamienić require na revert (unikamy w ten sposób dużo opłat za tekst!)
    s_addressToAmountFunded[msg.sender] += msg.value;
    s_funders.push(msg.sender);
  }

  modifier onlyOwner() {
    require(msg.sender == s_owner);
    _;
  }

  function withdraw() public payable onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
    for (
      uint256 funderIndex = 0;
      funderIndex < s_funders.length;
      funderIndex++
    ) {
      address funder = s_funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
  }

  function cheaperWithdraw() public payable onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
    address[] memory funders = s_funders; // memory jest o wiele tańsze
    // mappings can't be in memory, sorry!
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
  }
}
