pragma solidity ^0.4.15;

contract UniversalOrder {
    address public airlineOwner;

    modifier onlyAirline{ require(msg.sender==airlineOwner); _; }

    enum StatusOrder {
        Paid,
        Refunded
    }

    struct Order {
        address owner;
        address airlineAddress;
        uint price;
        StatusOrder statusOrder;
        uint departureDate; // timestamp
    }

    // OrderID => Order
    mapping (uint => Order) public orders;

    enum StatusRule {
        Delay,
        Cancelled
    }

    struct Rule {
        StatusRule statusRule;
        uint delay; // delay of the lag time (timestamp)
        uint ratioRefund;
    }

    Rule[] public rules;

    /** @dev Constructor.
     */
    function UniversalOrder() public {
        airlineOwner=msg.sender;
    }

    /** @dev Add a rule to refund.
     *  @param _statusRule Status of the rule.
     *  @param _delay Delay.
     *  @param _ratioRefund The ratio og the refund.
     */
    function addRefundRule (uint _statusRule, uint _delay, uint _ratioRefund) public {
        Rule storage rule;
        rule.statusRule = StatusRule.Delay;
        rule.delay = _delay;
        rule.ratioRefund = _ratioRefund;
    }

    /** @dev Book an order.
     *  @param _orderId Id of the order.
     *  @param _departureDate The departure date.
     */
    function book (uint _orderId, uint _departureDate) public payable {
        Order storage order;
        order.owner = msg.sender;
        order.price = msg.value;
        order.airlineAddress = airlineOwner;
        order.statusOrder = StatusOrder.Paid;
        order.departureDate = _departureDate;
        orders[_orderId] = order;
    }

    /** @dev Contract book success.
     *  @param _orderId Id of the order.
     */
    function reimburse (uint _orderId) public onlyAirline  {
        Order storage order = orders[_orderId];
        require(order.statusOrder != StatusOrder.Refunded);
        uint oneWei = 1 wei;
        order.owner.transfer(order.price * oneWei);
        order.statusOrder = StatusOrder.Refunded;
        orders[_orderId] = order;
    }

    /** @dev Contract book success.
     *  @param _orderId Id of the order.
     */
    function success (uint _orderId) public onlyAirline {
        Order storage order = orders[_orderId];
        uint oneWei = 1 wei;
        airlineOwner.transfer(order.price * oneWei);
    }
}
