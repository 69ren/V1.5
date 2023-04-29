/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../../common";
import type {
  UpgradeableBeacon,
  UpgradeableBeaconInterface,
} from "../../../../../@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "implementation_",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "previousOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "implementation",
        type: "address",
      },
    ],
    name: "Upgraded",
    type: "event",
  },
  {
    inputs: [],
    name: "implementation",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "renounceOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "newImplementation",
        type: "address",
      },
    ],
    name: "upgradeTo",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b506040516109cb3803806109cb83398181016040528101906100329190610247565b61004e61004361006360201b60201c565b61006b60201b60201c565b61005d8161012f60201b60201c565b50610317565b600033905090565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050816000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508173ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a35050565b61013e816101c160201b60201c565b61017d576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610174906102f7565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b6000808273ffffffffffffffffffffffffffffffffffffffff163b119050919050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610214826101e9565b9050919050565b61022481610209565b811461022f57600080fd5b50565b6000815190506102418161021b565b92915050565b60006020828403121561025d5761025c6101e4565b5b600061026b84828501610232565b91505092915050565b600082825260208201905092915050565b7f5570677261646561626c65426561636f6e3a20696d706c656d656e746174696f60008201527f6e206973206e6f74206120636f6e747261637400000000000000000000000000602082015250565b60006102e1603383610274565b91506102ec82610285565b604082019050919050565b60006020820190508181036000830152610310816102d4565b9050919050565b6106a5806103266000396000f3fe608060405234801561001057600080fd5b50600436106100575760003560e01c80633659cfe61461005c5780635c60da1b14610078578063715018a6146100965780638da5cb5b146100a0578063f2fde38b146100be575b600080fd5b61007660048036038101906100719190610477565b6100da565b005b610080610131565b60405161008d91906104b3565b60405180910390f35b61009e61015b565b005b6100a861016f565b6040516100b591906104b3565b60405180910390f35b6100d860048036038101906100d39190610477565b610198565b005b6100e261021b565b6100eb81610299565b8073ffffffffffffffffffffffffffffffffffffffff167fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b60405160405180910390a250565b6000600160009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b61016361021b565b61016d6000610325565b565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b6101a061021b565b600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff160361020f576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161020690610551565b60405180910390fd5b61021881610325565b50565b6102236103e9565b73ffffffffffffffffffffffffffffffffffffffff1661024161016f565b73ffffffffffffffffffffffffffffffffffffffff1614610297576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161028e906105bd565b60405180910390fd5b565b6102a2816103f1565b6102e1576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016102d89061064f565b60405180910390fd5b80600160006101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff16021790555050565b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff169050816000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508173ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff167f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e060405160405180910390a35050565b600033905090565b6000808273ffffffffffffffffffffffffffffffffffffffff163b119050919050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061044482610419565b9050919050565b61045481610439565b811461045f57600080fd5b50565b6000813590506104718161044b565b92915050565b60006020828403121561048d5761048c610414565b5b600061049b84828501610462565b91505092915050565b6104ad81610439565b82525050565b60006020820190506104c860008301846104a4565b92915050565b600082825260208201905092915050565b7f4f776e61626c653a206e6577206f776e657220697320746865207a65726f206160008201527f6464726573730000000000000000000000000000000000000000000000000000602082015250565b600061053b6026836104ce565b9150610546826104df565b604082019050919050565b6000602082019050818103600083015261056a8161052e565b9050919050565b7f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572600082015250565b60006105a76020836104ce565b91506105b282610571565b602082019050919050565b600060208201905081810360008301526105d68161059a565b9050919050565b7f5570677261646561626c65426561636f6e3a20696d706c656d656e746174696f60008201527f6e206973206e6f74206120636f6e747261637400000000000000000000000000602082015250565b60006106396033836104ce565b9150610644826105dd565b604082019050919050565b600060208201905081810360008301526106688161062c565b905091905056fea2646970667358221220d69e8e92745809479f1c6b08924400c32c983dee1e3e2b7fc8f8a6fba4e444d264736f6c63430008130033";

type UpgradeableBeaconConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: UpgradeableBeaconConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class UpgradeableBeacon__factory extends ContractFactory {
  constructor(...args: UpgradeableBeaconConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    implementation_: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<UpgradeableBeacon> {
    return super.deploy(
      implementation_,
      overrides || {}
    ) as Promise<UpgradeableBeacon>;
  }
  override getDeployTransaction(
    implementation_: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(implementation_, overrides || {});
  }
  override attach(address: string): UpgradeableBeacon {
    return super.attach(address) as UpgradeableBeacon;
  }
  override connect(signer: Signer): UpgradeableBeacon__factory {
    return super.connect(signer) as UpgradeableBeacon__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): UpgradeableBeaconInterface {
    return new utils.Interface(_abi) as UpgradeableBeaconInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): UpgradeableBeacon {
    return new Contract(address, _abi, signerOrProvider) as UpgradeableBeacon;
  }
}
