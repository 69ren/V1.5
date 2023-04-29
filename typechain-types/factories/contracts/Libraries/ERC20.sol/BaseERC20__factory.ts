/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../../common";
import type {
  BaseERC20,
  BaseERC20Interface,
} from "../../../../contracts/Libraries/ERC20.sol/BaseERC20";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint8",
        name: "version",
        type: "uint8",
      },
    ],
    name: "Initialized",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "allowance",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "nonces",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "deadline",
        type: "uint256",
      },
      {
        internalType: "uint8",
        name: "v",
        type: "uint8",
      },
      {
        internalType: "bytes32",
        name: "r",
        type: "bytes32",
      },
      {
        internalType: "bytes32",
        name: "s",
        type: "bytes32",
      },
    ],
    name: "permit",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "transfer",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b5061155b806100206000396000f3fe608060405234801561001057600080fd5b50600436106100a95760003560e01c806370a082311161007157806370a08231146101685780637ecebe001461019857806395d89b41146101c8578063a9059cbb146101e6578063d505accf14610216578063dd62ed3e14610232576100a9565b806306fdde03146100ae578063095ea7b3146100cc57806318160ddd146100fc57806323b872dd1461011a578063313ce5671461014a575b600080fd5b6100b6610262565b6040516100c39190610c94565b60405180910390f35b6100e660048036038101906100e19190610d4f565b6102f0565b6040516100f39190610daa565b60405180910390f35b6101046103e2565b6040516101119190610dd4565b60405180910390f35b610134600480360381019061012f9190610def565b6103e8565b6040516101419190610daa565b60405180910390f35b6101526105f6565b60405161015f9190610e5e565b60405180910390f35b610182600480360381019061017d9190610e79565b6105fb565b60405161018f9190610dd4565b60405180910390f35b6101b260048036038101906101ad9190610e79565b610613565b6040516101bf9190610dd4565b60405180910390f35b6101d061062b565b6040516101dd9190610c94565b60405180910390f35b61020060048036038101906101fb9190610d4f565b6106b9565b60405161020d9190610daa565b60405180910390f35b610230600480360381019061022b9190610f08565b6106d0565b005b61024c60048036038101906102479190610faa565b610a7a565b6040516102599190610dd4565b60405180910390f35b6001805461026f90611019565b80601f016020809104026020016040519081016040528092919081815260200182805461029b90611019565b80156102e85780601f106102bd576101008083540402835291602001916102e8565b820191906000526020600020905b8154815290600101906020018083116102cb57829003601f168201915b505050505081565b600081600360003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925846040516103d09190610dd4565b60405180910390a36001905092915050565b60045481565b600081600360008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205410156104a9576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016104a090611096565b60405180910390fd5b7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff600360008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002054146105e05781600360008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282546105d891906110e5565b925050819055505b6105eb848484610a9f565b600190509392505050565b601281565b60056020528060005260406000206000915090505481565b60076020528060005260406000206000915090505481565b6002805461063890611019565b80601f016020809104026020016040519081016040528092919081815260200182805461066490611019565b80156106b15780601f10610686576101008083540402835291602001916106b1565b820191906000526020600020905b81548152906001019060200180831161069457829003601f168201915b505050505081565b60006106c6338484610a9f565b6001905092915050565b42841015610713576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161070a90611165565b60405180910390fd5b7f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f60016040516107439190611228565b60405180910390206040518060400160405280600181526020017f310000000000000000000000000000000000000000000000000000000000000081525080519060200120463060405160200161079e95949392919061125d565b6040516020818303038152906040528051906020012060068190555060006006547f6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c960001b898989600760008e73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000815480929190610836906112b0565b919050558a604051602001610850969594939291906112f8565b604051602081830303815290604052805190602001206040516020016108779291906113d1565b6040516020818303038152906040528051906020012090506000600182868686604051600081526020016040526040516108b49493929190611408565b6020604051602081039080840390855afa1580156108d6573d6000803e3d6000fd5b505050602060405103519050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff161415801561094a57508873ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff16145b610989576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161098090611499565b60405180910390fd5b86600360008b73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008a73ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508773ffffffffffffffffffffffffffffffffffffffff168973ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92589604051610a679190610dd4565b60405180910390a3505050505050505050565b6003602052816000526040600020602052806000526040600020600091509150505481565b60008111610ae2576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610ad990611505565b60405180910390fd5b610aeb83610c01565b80600560008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254610b3a91906110e5565b92505081905550610b4a82610c01565b80600560008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825401925050819055508173ffffffffffffffffffffffffffffffffffffffff168373ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef83604051610bf49190610dd4565b60405180910390a3505050565b50565b600081519050919050565b600082825260208201905092915050565b60005b83811015610c3e578082015181840152602081019050610c23565b60008484015250505050565b6000601f19601f8301169050919050565b6000610c6682610c04565b610c708185610c0f565b9350610c80818560208601610c20565b610c8981610c4a565b840191505092915050565b60006020820190508181036000830152610cae8184610c5b565b905092915050565b600080fd5b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b6000610ce682610cbb565b9050919050565b610cf681610cdb565b8114610d0157600080fd5b50565b600081359050610d1381610ced565b92915050565b6000819050919050565b610d2c81610d19565b8114610d3757600080fd5b50565b600081359050610d4981610d23565b92915050565b60008060408385031215610d6657610d65610cb6565b5b6000610d7485828601610d04565b9250506020610d8585828601610d3a565b9150509250929050565b60008115159050919050565b610da481610d8f565b82525050565b6000602082019050610dbf6000830184610d9b565b92915050565b610dce81610d19565b82525050565b6000602082019050610de96000830184610dc5565b92915050565b600080600060608486031215610e0857610e07610cb6565b5b6000610e1686828701610d04565b9350506020610e2786828701610d04565b9250506040610e3886828701610d3a565b9150509250925092565b600060ff82169050919050565b610e5881610e42565b82525050565b6000602082019050610e736000830184610e4f565b92915050565b600060208284031215610e8f57610e8e610cb6565b5b6000610e9d84828501610d04565b91505092915050565b610eaf81610e42565b8114610eba57600080fd5b50565b600081359050610ecc81610ea6565b92915050565b6000819050919050565b610ee581610ed2565b8114610ef057600080fd5b50565b600081359050610f0281610edc565b92915050565b600080600080600080600060e0888a031215610f2757610f26610cb6565b5b6000610f358a828b01610d04565b9750506020610f468a828b01610d04565b9650506040610f578a828b01610d3a565b9550506060610f688a828b01610d3a565b9450506080610f798a828b01610ebd565b93505060a0610f8a8a828b01610ef3565b92505060c0610f9b8a828b01610ef3565b91505092959891949750929550565b60008060408385031215610fc157610fc0610cb6565b5b6000610fcf85828601610d04565b9250506020610fe085828601610d04565b9150509250929050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052602260045260246000fd5b6000600282049050600182168061103157607f821691505b60208210810361104457611043610fea565b5b50919050565b7f496e73756666696369656e7420616c6c6f77616e636500000000000000000000600082015250565b6000611080601683610c0f565b915061108b8261104a565b602082019050919050565b600060208201905081810360008301526110af81611073565b9050919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b60006110f082610d19565b91506110fb83610d19565b9250828203905081811115611113576111126110b6565b5b92915050565b7f506169723a204558504952454400000000000000000000000000000000000000600082015250565b600061114f600d83610c0f565b915061115a82611119565b602082019050919050565b6000602082019050818103600083015261117e81611142565b9050919050565b600081905092915050565b60008190508160005260206000209050919050565b600081546111b281611019565b6111bc8186611185565b945060018216600081146111d757600181146111ec5761121f565b60ff198316865281151582028601935061121f565b6111f585611190565b60005b83811015611217578154818901526001820191506020810190506111f8565b838801955050505b50505092915050565b600061123482846111a5565b915081905092915050565b61124881610ed2565b82525050565b61125781610cdb565b82525050565b600060a082019050611272600083018861123f565b61127f602083018761123f565b61128c604083018661123f565b6112996060830185610dc5565b6112a6608083018461124e565b9695505050505050565b60006112bb82610d19565b91507fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82036112ed576112ec6110b6565b5b600182019050919050565b600060c08201905061130d600083018961123f565b61131a602083018861124e565b611327604083018761124e565b6113346060830186610dc5565b6113416080830185610dc5565b61134e60a0830184610dc5565b979650505050505050565b600081905092915050565b7f1901000000000000000000000000000000000000000000000000000000000000600082015250565b600061139a600283611359565b91506113a582611364565b600282019050919050565b6000819050919050565b6113cb6113c682610ed2565b6113b0565b82525050565b60006113dc8261138d565b91506113e882856113ba565b6020820191506113f882846113ba565b6020820191508190509392505050565b600060808201905061141d600083018761123f565b61142a6020830186610e4f565b611437604083018561123f565b611444606083018461123f565b95945050505050565b7f506169723a20494e56414c49445f5349474e4154555245000000000000000000600082015250565b6000611483601783610c0f565b915061148e8261144d565b602082019050919050565b600060208201905081810360008301526114b281611476565b9050919050565b7f43616e2774207472616e73666572203021000000000000000000000000000000600082015250565b60006114ef601183610c0f565b91506114fa826114b9565b602082019050919050565b6000602082019050818103600083015261151e816114e2565b905091905056fea2646970667358221220dc80021527275e82da3a16e7c65f330de45b2ec65571230e11bdba808b13044d64736f6c63430008130033";

type BaseERC20ConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: BaseERC20ConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class BaseERC20__factory extends ContractFactory {
  constructor(...args: BaseERC20ConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<BaseERC20> {
    return super.deploy(overrides || {}) as Promise<BaseERC20>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): BaseERC20 {
    return super.attach(address) as BaseERC20;
  }
  override connect(signer: Signer): BaseERC20__factory {
    return super.connect(signer) as BaseERC20__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): BaseERC20Interface {
    return new utils.Interface(_abi) as BaseERC20Interface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): BaseERC20 {
    return new Contract(address, _abi, signerOrProvider) as BaseERC20;
  }
}