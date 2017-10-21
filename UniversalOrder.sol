pragma solidity ^0.4.15;

contract UniversalOrder {
    address public owner;

    // modifier
    modifier onlyAirline{ require(msg.sender==owner); _; }

    enum StatusOrder {
        Paid,
        Refunded
    }

    struct Order {
        address airlineAddress;
        address orderAddress;
        uint price;
        StatusOrder statusOrder;
        uint departureDate; // timestamp
        bool flightCancelled; // default false
        string signature;
        uint createdAt;
    }

    // OrderID => Order
    mapping (uint => Order) public orders;

    enum StatusRule {
        Delay,
        Cancelled
    }

    struct Rule {
        uint delay; // delay of the lag time (timestamp), 0 for flight cancelled
        uint ratioRefund;
    }

    Rule[] public rules; // FIXME better use linked list by rule.delay

    function UniversalOrder () public {
        owner = msg.sender;
    }

    /** @dev Add a rule to refund.
     *  @param _delay Delay.
     *  @param _ratioRefund The ratio on the refund.
     */
    function addRefundRule (uint _delay, uint _ratioRefund) public {
        Rule storage rule;
        rule.delay = _delay;
        rule.ratioRefund = _ratioRefund;
    }

    /** @dev Book an order.
     *  @param _orderId Id of the order.
     *  @param _departureDate The departure date.
     *  @param _signature Signature of the contract signed by the airline.
     */
    function book (uint _orderId, uint _departureDate, string _signature) public payable {
        Order storage order;
        order.orderAddress = msg.sender;
        order.price = msg.value;
        order.statusOrder = StatusOrder.Paid;
        order.departureDate = _departureDate;
        order.signature = _signature;
        order.createdAt = now;
        orders[_orderId] = order;
    }

    /** @dev Contract book success.
     *  @param _orderId Id of the order.
     *  @param _forceDelayRatioRefund To test easier the workflow (ratio). UNTRUSTED (MOCK)
     *  @param _forceCancelled To test easier the workflow (timestamp). UNTRUSTED (MOCK)
     */
    function reimburse (uint _orderId, uint _forceDelayRatioRefund, uint _forceCancelled) public onlyAirline  {
        Order storage order = orders[_orderId];
        require(order.statusOrder != StatusOrder.Refunded);
        uint expirationDate;
        uint oneWei = 1 wei;

        // MOCK for the hackaton to avoid to wait a cancel flight
        if (_forceCancelled == 1) {
            order.orderAddress.transfer(order.price);
            order.statusOrder = StatusOrder.Refunded;
            orders[_orderId] = order;
        // MOCK for the hackaton to avoid to wait a flight delay
        } else if (_forceDelayRatioRefund > 0) {
            order.orderAddress.transfer(order.price * oneWei * _forceDelayRatioRefund);
            order.statusOrder = StatusOrder.Refunded;
            orders[_orderId] = order;
        } else {
            for (uint i=0; i<rules.length; ++i) {
                 expirationDate = now + rules[i].delay;
                if (order.flightCancelled) {
                    order.orderAddress.transfer(order.price * oneWei);
                    order.statusOrder = StatusOrder.Refunded;
                    orders[_orderId] = order;
                }
                if(expirationDate > order.departureDate) {
                    order.orderAddress.transfer(order.price * oneWei * rules[i].ratioRefund);
                    order.statusOrder = StatusOrder.Refunded;
                    orders[_orderId] = order;
                }
            }
        }
    }

    /** @dev Contract book success.
     *  @param _orderId Id of the order.
     */
    function success (uint _orderId) public onlyAirline {
        Order storage order = orders[_orderId];
        uint oneWei = 1 wei;
        msg.sender.transfer(order.price);
    }
}
