// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title TestToken
 * @dev 一个功能完整的 ERC20 代币合约，用于测试和空投
 * 
 * 特性:
 * - 标准 ERC20 功能
 * - 可销毁代币 (ERC20Burnable)
 * - 所有权管理 (Ownable)
 * - 无 Gas 费授权 (ERC20Permit)
 * - 初始供应量铸造给部署者
 */
contract TestToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    
    // 初始供应量: 1,000,000 个代币
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    
    // 最大供应量: 10,000,000 个代币
    uint256 public constant MAX_SUPPLY = 10_000_000 * 10**18;
    
    // 是否启用铸造功能
    bool public mintingEnabled;
    
    // 事件
    event MintingEnabled(address indexed owner);
    event MintingDisabled(address indexed owner);
    event TokensMinted(address indexed to, uint256 amount);
    
    /**
     * @dev 构造函数
     * @param name_ 代币名称
     * @param symbol_ 代币符号
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable(msg.sender) ERC20Permit(name_) {
        // 铸造初始供应量给部署者
        _mint(msg.sender, INITIAL_SUPPLY);
        
        // 默认启用铸造功能
        mintingEnabled = true;
        
        emit MintingEnabled(msg.sender);
    }
    
    /**
     * @dev 启用铸造功能 (只有 owner 可以调用)
     */
    function enableMinting() external onlyOwner {
        require(!mintingEnabled, "Minting is already enabled");
        mintingEnabled = true;
        emit MintingEnabled(msg.sender);
    }
    
    /**
     * @dev 禁用铸造功能 (只有 owner 可以调用)
     */
    function disableMinting() external onlyOwner {
        require(mintingEnabled, "Minting is already disabled");
        mintingEnabled = false;
        emit MintingDisabled(msg.sender);
    }
    
    /**
     * @dev 铸造新代币 (只有 owner 可以调用)
     * @param to 接收地址
     * @param amount 铸造数量
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(mintingEnabled, "Minting is disabled");
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
    
    /**
     * @dev 批量铸造代币 (只有 owner 可以调用)
     * @param recipients 接收地址数组
     * @param amounts 数量数组
     */
    function batchMint(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(mintingEnabled, "Minting is disabled");
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(recipients.length > 0, "Empty arrays");
        
        uint256 totalAmount = 0;
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot mint to zero address");
            require(amounts[i] > 0, "Amount must be greater than 0");
            totalAmount += amounts[i];
        }
        
        require(totalSupply() + totalAmount <= MAX_SUPPLY, "Exceeds max supply");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
            emit TokensMinted(recipients[i], amounts[i]);
        }
    }
    
    /**
     * @dev 销毁代币 (任何人都可以销毁自己的代币)
     * @param amount 销毁数量
     */
    function burn(uint256 amount) public override {
        super.burn(amount);
    }
    
    /**
     * @dev 从指定地址销毁代币 (需要授权)
     * @param from 销毁地址
     * @param amount 销毁数量
     */
    function burnFrom(address from, uint256 amount) public override {
        super.burnFrom(from, amount);
    }
    
    /**
     * @dev 获取代币信息
     * @return tokenName 代币名称
     * @return tokenSymbol 代币符号
     * @return tokenDecimals 小数位数
     * @return currentSupply 当前总供应量
     * @return maxSupply 最大供应量
     * @return isMintingEnabled 是否启用铸造
     */
    function getTokenInfo() external view returns (
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        uint256 currentSupply,
        uint256 maxSupply,
        bool isMintingEnabled
    ) {
        return (
            this.name(),
            this.symbol(),
            this.decimals(),
            this.totalSupply(),
            MAX_SUPPLY,
            mintingEnabled
        );
    }
    
    /**
     * @dev 检查地址是否有足够的代币
     * @param account 检查地址
     * @param amount 所需数量
     * @return 是否有足够代币
     */
    function hasEnoughTokens(address account, uint256 amount) external view returns (bool) {
        return balanceOf(account) >= amount;
    }
    
    /**
     * @dev 获取可铸造的代币数量
     * @return 可铸造数量
     */
    function getMintableAmount() external view returns (uint256) {
        if (!mintingEnabled) return 0;
        return MAX_SUPPLY - totalSupply();
    }
}