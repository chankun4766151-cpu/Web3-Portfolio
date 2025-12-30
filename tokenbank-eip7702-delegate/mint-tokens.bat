@echo off
echo ========================================
echo 正在铸造 1000 个 MyToken 到你的钱包...
echo ========================================
echo.
echo 钱包地址: 0x323BaecCa8d911037dcA6c465a6181A007302f22
echo MyToken 地址: 0xe7b200b17a51e3a036eceb1c2f22c57f691d01c5
echo.

cast send 0xe7b200b17a51e3a036eceb1c2f22c57f691d01c5 "mint(address,uint256)" 0x323BaecCa8d911037dcA6c465a6181A007302f22 1000000000000000000000 --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key 0xcd23408bc81aa656c44f5522737f6512cb61ec91e544f9eb444b1d07f2cc7204

echo.
echo ========================================
echo 完成！
echo ========================================
pause
