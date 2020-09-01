pragma solidity ^0.6.0;

interface ENS
{
	function owner(bytes32 node) external view returns (address);
}

interface IReverseRegistrar
{
	function setName(string calldata name) external returns (bytes32);
}

contract ENSReverseRegistration
{
	bytes32 internal constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

	function _setName(ENS ens, string memory name)
	internal
	{
		IReverseRegistrar(ens.owner(ADDR_REVERSE_NODE)).setName(name);
	}
}

interface IERC721
{
	function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IRegistry is IERC721
{
}

abstract contract RegistryEntry is ENSReverseRegistration
{
	IRegistry public registry;

	function _initialize(address _registry) internal
	{
		require(address(registry) == address(0), 'already initialized');
		registry = IRegistry(_registry);
	}

	function owner() public view returns (address)
	{
		return registry.ownerOf(uint256(address(this)));
	}

	modifier onlyOwner()
	{
		require(owner() == msg.sender, 'caller is not the owner');
		_;
	}

	function setName(address _ens, string calldata _name)
	external onlyOwner()
	{
		_setName(ENS(_ens), _name);
	}
}

contract Dataset is RegistryEntry
{
	/**
	 * Members
	 */
	string  public m_datasetName;
	bytes   public m_datasetMultiaddr;
	bytes32 public m_datasetChecksum;

	/**
	 * Constructor
	 */
	function initialize(
		string  memory _datasetName,
		bytes   memory _datasetMultiaddr,
		bytes32        _datasetChecksum)
	public
	{
		_initialize(msg.sender);
		m_datasetName      = _datasetName;
		m_datasetMultiaddr = _datasetMultiaddr;
		m_datasetChecksum  = _datasetChecksum;
	}
}