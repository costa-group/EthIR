pragma solidity ^0.5.14;


contract SwapProxyInterface {

    function name() public view returns(string memory);

    function getSwapQuantity(address src, address dst, uint256 srcQty) public view returns(uint256);

    function getSwapRate(address src, address dst, uint256 srcQty) public view returns(uint256);

    function executeSwap(address srcToken, uint256 srcQty, address dstToken, address dstAddress) public returns(bool);

}



contract ERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function decimals() public view returns(uint);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

}



contract Auction {

    function bidAndWithdraw(address _rebalancingSetToken, uint256 _quantity, bool _allowPartialFill) external;

}



contract AdminRole {



    mapping (address => bool) adminGroup;

    address payable owner;



    constructor () public {

        adminGroup[msg.sender] = true;

        owner = msg.sender;

    }



    modifier onlyAdmin() {

        require(

            isAdmin(msg.sender),

            "The caller is not Admin"

        );

        _;

    }



    modifier onlyOwner {

        require(

            owner == msg.sender,

            "The caller is not Owner"

        );

        _;

    }



    function addAdmin(address addr) external onlyAdmin {

        adminGroup[addr] = true;

    }

    function delAdmin(address addr) external onlyAdmin {

        adminGroup[addr] = false;

    }



    function isAdmin(address addr) public view returns(bool) {

        return adminGroup[addr];

    }



    function kill() external onlyOwner {

        selfdestruct(owner);

    }

}



contract Withdrawable is AdminRole {

    /*

     * External Function to withdraw founds -> Gas or Tokens

     */

    function withdrawTo (address payable dst, uint founds, address token) external onlyAdmin {

        if (token == address(0))

            require (address(this).balance >= founds);

        else {

            ERC20 erc20 = ERC20(token);

            require (erc20.balanceOf(address(this)) >= founds);

        }

        sendFounds(dst,founds, token);

    }



    /*

     * Function to send founds -> Gas or Tokens

     */

    function sendFounds(address payable dst, uint amount, address token) internal returns(bool) {

        ERC20 erc20;

        if (token == address(0))

            require(address(dst).send(amount), "Impossible send founds");

        else {

            erc20 = ERC20(token);

            require(erc20.transfer(dst, amount), "Impossible send founds");

        }

    }

}





contract Swapper is Withdrawable {



    event TokenSwapped(address indexed srcToken, address indexed dstToken, string swapProxy);



    address[10] swapProxy;

    uint256 swapProxySize = 0;



    function addSwapProxy (address addr) external onlyAdmin {

        require(swapProxySize < 10, "Max SwapProxy has reatched");



        for (uint256 i; i < 10; i++ ) {

            if (swapProxy[i] == address(0)) {

                swapProxy[i] = addr;

                swapProxySize = swapProxySize + 1;

                return;

            }

        }

        revert("Unable to found free slot");

    }



    function delSwapProxy(address addr) external onlyAdmin {

        for (uint256 i; i < 10; i++ ) {

            if (swapProxy[i] == addr) {

                swapProxy[i] = address(0);

                swapProxySize = swapProxySize - 1;

                return;

            }

        }

        revert("Unable to found a proxy");

    }



    function getBestSwapRate(address src, address dst, uint256 srcQty) external view

        returns (string memory name, uint256 rate, uint256 index)

    {

        SwapProxyInterface spi;



        /**

         * Si no existe nigun swap proxy

         */

        if (swapProxySize == 0)

            return (name,rate,index);



        (index, rate) = getBestRate(src,dst,srcQty);



        if (rate != 0) {

            spi = SwapProxyInterface(swapProxy[index]);

            name = spi.name();

        }

    }



    function doSwapOnBest(address srcToken, uint256 srcQty, address dstToken, address dstAddress) external {

        ERC20 token = ERC20(srcToken);

        require(token.transferFrom(msg.sender, address(this), srcQty), "Unable to transferFrom()");



        swapOnBest(srcToken, srcQty, dstToken, dstAddress);

    }





    function getBestRate(address src, address dst, uint256 srcQty)

        internal view returns(uint256 index, uint256 rate )

    {

        SwapProxyInterface spi;

        uint256 tmp;

        uint256 i;





        for (i = 0; i < 10; i++) {

            if (swapProxy[i] != address(0)) {

                spi = SwapProxyInterface(swapProxy[i]);

                tmp = spi.getSwapRate(src,dst,srcQty);

                if (tmp > rate) {

                    rate = tmp;

                    index = i;

                }

            }

        }

    }



    function swapOnBest(address srcToken, uint256 srcQty, address dstToken, address dstAddress)

        internal returns(bool)

    {

        SwapProxyInterface spi;

        ERC20 token = ERC20(srcToken);

        uint256 index;

        uint256 rate;



        require(swapProxySize != 0, "Unable to found a configured swap");



        (index,rate) = getBestRate(srcToken,dstToken,srcQty);



        require(rate != 0, "Unable to found a valid rate");



        // Set the spender's token allowance to tokenQty

        require(token.approve(swapProxy[index], srcQty), "Unable to appove()");



        spi = SwapProxyInterface(swapProxy[index]);



        require(spi.executeSwap(srcToken,srcQty,dstToken,dstAddress), "Unable to executeSwap");



        emit TokenSwapped(srcToken,dstToken,spi.name());



        return true;

    }

}





contract Bidder is Swapper {

    address public auctionAddress = 0xe23FB31dD2edacEbF7d92720358bB92445F47fDB;

    address public transferProxy = 0x882d80D3a191859d64477eb78Cca46599307ec1C;



    function bidAndSwap(address tokenset, uint256 quantity, uint256 srcQty, address src, address dst) external {

        Auction auction = Auction(auctionAddress);

        ERC20 srcToken = ERC20(src);

        ERC20 dstToken = ERC20(dst);

        uint256 dst_startBalance = dstToken.balanceOf(address(this));



        /**

         * 1- Traemos los fondos para poder participar de la subasta

         */

        require(srcToken.transferFrom(msg.sender,address(this),srcQty), "Unable to transferFrom()");



        /**

         * 2- Habilitamos el approve al transfer proxy si no esta habilitado

         */

        require(srcToken.approve(transferProxy,srcQty), "Unable to approve");





        /**

         * 3- Participamos en la subasta

         */

        auction.bidAndWithdraw(tokenset,quantity,true);



        /**

         * 4- En este punto debemos tener mas balance del dstToken y esa diferencia es la que tenemos que

         *    intercambiar

         */

        swapOnBest(dst,dstToken.balanceOf(address(this))-dst_startBalance,src,msg.sender);

    }

}