import { Provider, Wallet } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";

// load env file
import dotenv from "dotenv";
dotenv.config();

// load contract artifact. Make sure to compile first!
import * as ContractArtifact from "../artifacts-zk/contracts/CompanyReviewContract.sol/CompanyReviewContract.json";

const PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY || "";

if (!PRIVATE_KEY)
  throw "⛔️ Private key not detected! Add it to the .env file!";

// Address of the contract on zksync testnet
const CONTRACT_ADDRESS = "0x54803b00E89114D2986B1B7742615548e48920A6";

if (!CONTRACT_ADDRESS) throw "⛔️ Contract address not provided";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running script to interact with contract ${CONTRACT_ADDRESS}`);

  // Initialize the provider.
  // @ts-ignore
  const provider = new Provider(hre.userConfig.networks?.zkSyncTestnet?.url);
  const signer = new Wallet(PRIVATE_KEY, provider);

  // Initialize contract instance
  const contract = new ethers.Contract(
    CONTRACT_ADDRESS,
    ContractArtifact.abi,
    signer
  );

  
  const message = "0x84960ca8edA0936A2AceBd818418be091CFF1720"
  const companyAddress = "0x84960ca8edA0936A2AceBd818418be091CFF1720"
  let messageHash = ethers.utils.id(message);
  let messageHashBytes = ethers.utils.arrayify(messageHash)

// Sign the binary data
let flatSig = await signer.signMessage(messageHashBytes);

// For Solidity, we need the expanded-format of a signature
let sig = ethers.utils.splitSignature(flatSig);
  let res = await contract.verifyWithRVS(signer.address,messageHash,sig.r, sig.s, sig.v)
  console.log(res);
  const tx = await contract.registerCompany(companyAddress, messageHash, sig.r, sig.s, sig.v);
  let result = await tx.wait();
  console.log(result);
    const owner = await contract.owner();
    console.log(owner);
  const isRegistered = await contract.companies("0x84960ca8edA0936A2AceBd818418be091CFF1720")
  console.log(isRegistered);

  // Read message after transaction
  
}
