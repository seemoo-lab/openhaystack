#!/bin/bash

cleanup() {
    echo "### done"
}


# Parameter parsing
while [[ $# -gt 0 ]]; do
    KEY="$1"
    case "$KEY" in
        -v|--venvdir)
            VENV_DIR="$2"
            shift
            shift
        ;;
        -h|--help)
            echo "flash_nrf.sh - Flash the OpenHaystack firmware onto a nRF board"
            echo ""
            echo "  This script will create a virtual environment for the required tools."
            echo ""
            echo "Call: flash_nrf.sh [-v <dir>] PUBLIC_KEY SYMMETRIC_KEY UPDATE_INTERVAL"
            echo ""
            echo "Required Arguments:"
            echo "  PUBLIC_KEY"
            echo "     The base64-encoded public key"
            echo "  SYMMETRIC_KEY"
            echo "     The base64-encoded symmetric key"
            echo "  UPDATE_INTERVAL"
            echo "     Refresh interval for key derivation in minutes"
            echo ""
            echo "Optional Arguments:"
            echo "  -h, --help"
            echo "      Show this message and exit."
            echo "  -v, --venvdir <dir>"
            echo "      Select Python virtual environment with esptool installed."
            echo "      If the directory does not exist, it will be created."
            exit 1
        ;;
        *)
            if [[ -z "$PUBKEY" ]]; then
                PUBKEY="$1"
                shift

                if [[ -z "$SYMKEY" ]]; then
                    SYMKEY="$1"
                    shift

                    if [[ -z "$UPDATE_INTERVAL" ]]; then
                        UPDATE_INTERVAL="$1"
                        shift
                    else
                        echo "Got unexpected parameter $1"
                        exit 1
                fi
                else
                    echo "Got unexpected parameter $1"
                    exit 1
                fi
            else
                echo "Got unexpected parameter $1"
                exit 1
            fi
        ;;
    esac
done


# Directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Defaults: Directory for the virtual environment
VENV_DIR="$SCRIPT_DIR/venv"

# Sanity check: Pubkey exists
if [[ -z "$PUBKEY" ]]; then
    echo "Missing public key, call with --help for usage"
    exit 1
fi

# Sanity check: Symmetric key exists
if [[ -z "$SYMKEY" ]]; then
    echo "Missing symmetric key, call with --help for usage"
    exit 1
fi

#Sanity check: update Interval exists
if [[ -z "$UPDATE_INTERVAL" ]]; then
    echo "Missing update interval, call with --help for usage"
    exit 1
fi


# Setup the virtual environment
if [[ ! -d "$VENV_DIR" ]]; then
    # Create the virtual environment
    echo "# Setting up python env in folder $VENV_DIR"
    PYTHON="$(which python3)"
    if [[ -z "$PYTHON" ]]; then
        PYTHON="$(which python)"
    fi
    if [[ -z "$PYTHON" ]]; then
        echo "Could not find a Python installation, please install Python 3."
        exit 1
    fi
    if ! ($PYTHON -V 2>&1 | grep "Python 3" > /dev/null); then
        echo "Executing \"$PYTHON\" does not run Python 3, please make sure that python3 or python on your PATH points to Python 3"
        exit 1
    fi
    if ! ($PYTHON -c "import venv" &> /dev/null); then
        echo "Python 3 module \"venv\" was not found."
        exit 1
    fi
    $PYTHON -m venv "$VENV_DIR"
    if [[ $? != 0 ]]; then
        echo "Creating the virtual environment in $VENV_DIR failed."
        exit 1
    fi
    echo "# Activate venv and install pynrfjprog and intelhex"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install pynrfjprog && pip install intelhex
    if [[ $? != 0 ]]; then
        echo "Could not install Python 3 module pynrfjprog in $VENV_DIR";
        exit 1
    fi
else
    source "$VENV_DIR/bin/activate"
fi

# Call flash_nrf.py. Errors from here on are critical
set -e
trap cleanup INT TERM EXIT
echo "### Executing python script ###"
python3 "$(dirname "$0")"/flash_nrf.py --public-key $PUBKEY --symmetric-key $SYMKEY --update-interval $UPDATE_INTERVAL --path-to-hex "$(dirname "$0")"/
echo "### Python script finished  ###"
