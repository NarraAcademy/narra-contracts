#!/bin/bash

# 设置环境变量
export PRIVATE_KEY="0xda0cd5d1cdfd0835da4b1bd1c6b19307f955082fcfe971f2b32ce19c5dbe4d0d"
export USER_PRIVATE_KEY="0xda0cd5d1cdfd0835da4b1bd1c6b19307f955082fcfe971f2b32ce19c5dbe4d0d"
export RPC_URL="https://bsc-testnet.bnbchain.org"
export CONTRACT_ADDRESS="0x0A627E9b75b79Aa7c7323f72906560263CDCD7D3"
export USER_ADDRESS="0x83E5584c0A2C4ead17FAaD716aB4eEFa540B0000"

echo "=== Testing SimpleCheckIn Contract ==="

# 1. 获取域名分隔符
echo "Domain Separator:"
cast call $CONTRACT_ADDRESS "getDomainSeparator()" --rpc-url $RPC_URL

# 2. 获取用户当前信息
echo "User Info before check-in:"
cast call $CONTRACT_ADDRESS "getUserInfo(address)(uint256,uint256)" $USER_ADDRESS --rpc-url $RPC_URL

# 3. 生成签名数据（这里需要更复杂的EIP-712处理）
echo "Generating signature..."

# 4. 调用checkin方法
echo "Calling checkInWithSignature..."
cast send $CONTRACT_ADDRESS "checkInWithSignature(address,bytes)" $USER_ADDRESS "0x签名数据" --private-key $PRIVATE_KEY --rpc-url $RPC_URL

# 5. 查询用户更新后的信息
echo "User Info after check-in:"
cast call $CONTRACT_ADDRESS "getUserInfo(address)(uint256,uint256)" $USER_ADDRESS --rpc-url $RPC_URL

echo "=== Test Complete ==="