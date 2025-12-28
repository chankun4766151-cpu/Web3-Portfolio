const readlineSync = require('readline-sync');
const { generateWallet, loadWallet, savePrivateKey, getETHBalance } = require('./wallet');
const { getERC20Balance, getTokenSymbol, sendERC20Transfer } = require('./erc20');

// 显示主菜单
function showMenu() {
    console.log('\n' + '='.repeat(50));
    console.log('🔐 CLI 钱包 - Sepolia 测试网');
    console.log('='.repeat(50));
    console.log('1. 🆕 生成新钱包');
    console.log('2. 💰 查询余额');
    console.log('3. 📤 发送 ERC20 代币');
    console.log('4. 👤 查看当前地址');
    console.log('0. 🚪 退出');
    console.log('='.repeat(50));
}

// 生成新钱包
async function handleGenerateWallet() {
    console.log('\n🔑 生成新钱包中...');

    const existingWallet = loadWallet();
    if (existingWallet) {
        const confirm = readlineSync.keyInYN('⚠️  已存在钱包，是否覆盖？');
        if (!confirm) {
            console.log('❌ 取消操作');
            return;
        }
    }

    const wallet = generateWallet();
    savePrivateKey(wallet.privateKey);

    console.log('\n✅ 钱包生成成功！');
    console.log(`📍 地址: ${wallet.address}`);
    console.log(`🔑 私钥: ${wallet.privateKey}`);
    console.log('\n⚠️  请务必安全保管您的私钥！');
    console.log('💡 私钥已保存到 .env 文件中');

    // 查询余额
    console.log('\n💰 查询余额中...');
    const balance = await getETHBalance(wallet.address);
    console.log(`💎 ETH 余额: ${balance} ETH`);

    if (parseFloat(balance) === 0) {
        console.log('\n💡 提示: 您可以从以下水龙头获取测试 ETH:');
        console.log('   - https://sepoliafaucet.com/');
        console.log('   - https://www.alchemy.com/faucets/ethereum-sepolia');
    }
}

// 查询余额
async function handleCheckBalance() {
    const wallet = loadWallet();
    if (!wallet) {
        console.log('\n❌ 未找到钱包，请先生成钱包！');
        return;
    }

    console.log(`\n📍 地址: ${wallet.address}`);
    console.log('\n💰 查询余额中...');

    try {
        // 查询 ETH 余额
        const ethBalance = await getETHBalance(wallet.address);
        console.log(`💎 ETH 余额: ${ethBalance} ETH`);

        // 查询 ERC20 余额
        const tokenSymbol = await getTokenSymbol();
        const tokenBalance = await getERC20Balance(wallet.address);
        console.log(`🪙 ${tokenSymbol} 余额: ${tokenBalance} ${tokenSymbol}`);
    } catch (error) {
        console.log(`❌ 查询余额失败: ${error.message}`);
    }
}

// 发送 ERC20 代币
async function handleSendERC20() {
    const wallet = loadWallet();
    if (!wallet) {
        console.log('\n❌ 未找到钱包，请先生成钱包！');
        return;
    }

    console.log(`\n📍 当前地址: ${wallet.address}`);

    try {
        // 查询余额
        const tokenSymbol = await getTokenSymbol();
        const balance = await getERC20Balance(wallet.address);
        console.log(`🪙 ${tokenSymbol} 余额: ${balance} ${tokenSymbol}`);

        if (parseFloat(balance) === 0) {
            console.log('\n❌ 余额不足，无法发送代币');
            return;
        }

        // 输入接收地址
        console.log('\n');
        const toAddress = readlineSync.question('📬 请输入接收地址: ');

        if (!toAddress.startsWith('0x') || toAddress.length !== 42) {
            console.log('❌ 无效的地址格式');
            return;
        }

        // 输入金额
        const amount = readlineSync.question(`💵 请输入发送数量（当前余额: ${balance} ${tokenSymbol}）: `);

        if (parseFloat(amount) <= 0 || parseFloat(amount) > parseFloat(balance)) {
            console.log('❌ 无效的金额');
            return;
        }

        // 确认交易
        console.log('\n📋 交易信息:');
        console.log(`   从: ${wallet.address}`);
        console.log(`   到: ${toAddress}`);
        console.log(`   金额: ${amount} ${tokenSymbol}`);
        console.log('');

        const confirm = readlineSync.keyInYN('确认发送？');
        if (!confirm) {
            console.log('❌ 取消交易');
            return;
        }

        // 发送交易
        const result = await sendERC20Transfer(toAddress, amount);

        console.log('\n' + '='.repeat(50));
        console.log('🎉 交易完成！');
        console.log('='.repeat(50));
        console.log(`📤 交易哈希: ${result.hash}`);
        console.log(`🔗 浏览器链接: ${result.explorerUrl}`);
        console.log('='.repeat(50));

    } catch (error) {
        console.log(`\n❌ 交易失败: ${error.message}`);
    }
}

// 查看当前地址
function handleShowAddress() {
    const wallet = loadWallet();
    if (!wallet) {
        console.log('\n❌ 未找到钱包，请先生成钱包！');
        return;
    }

    console.log(`\n📍 当前地址: ${wallet.address}`);
    console.log(`🔑 私钥: ${wallet.privateKey}`);
}

// 主程序
async function main() {
    console.log('🚀 CLI 钱包启动中...\n');

    let running = true;

    while (running) {
        showMenu();
        const choice = readlineSync.question('\n请选择操作 (0-4): ');

        switch (choice) {
            case '1':
                await handleGenerateWallet();
                break;
            case '2':
                await handleCheckBalance();
                break;
            case '3':
                await handleSendERC20();
                break;
            case '4':
                handleShowAddress();
                break;
            case '0':
                console.log('\n👋 再见！');
                running = false;
                break;
            default:
                console.log('\n❌ 无效的选项，请重新选择');
        }

        if (running) {
            console.log('\n按 Enter 键继续...');
            readlineSync.question();
        }
    }
}

// 启动程序
main().catch(error => {
    console.error('\n💥 发生错误:', error.message);
    process.exit(1);
});
