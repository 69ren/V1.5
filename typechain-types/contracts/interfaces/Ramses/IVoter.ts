/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../../common";

export interface IVoterInterface extends utils.Interface {
  functions: {
    "_ve()": FunctionFragment;
    "base()": FunctionFragment;
    "bribes(address)": FunctionFragment;
    "createGauge(address)": FunctionFragment;
    "feeDistributers(address)": FunctionFragment;
    "gauges(address)": FunctionFragment;
    "poolForGauge(address)": FunctionFragment;
    "vote(uint256,address[],uint256[])": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "_ve"
      | "base"
      | "bribes"
      | "createGauge"
      | "feeDistributers"
      | "gauges"
      | "poolForGauge"
      | "vote"
  ): FunctionFragment;

  encodeFunctionData(functionFragment: "_ve", values?: undefined): string;
  encodeFunctionData(functionFragment: "base", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "bribes",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "createGauge",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "feeDistributers",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "gauges",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "poolForGauge",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "vote",
    values: [
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<string>[],
      PromiseOrValue<BigNumberish>[]
    ]
  ): string;

  decodeFunctionResult(functionFragment: "_ve", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "base", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "bribes", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "createGauge",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "feeDistributers",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "gauges", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "poolForGauge",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "vote", data: BytesLike): Result;

  events: {};
}

export interface IVoter extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IVoterInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    _ve(overrides?: CallOverrides): Promise<[string]>;

    base(overrides?: CallOverrides): Promise<[string]>;

    bribes(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[string] & { bribe: string }>;

    createGauge(
      pool: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    feeDistributers(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    gauges(
      pool: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[string] & { gauge: string }>;

    poolForGauge(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[string] & { pool: string }>;

    vote(
      tokenId: PromiseOrValue<BigNumberish>,
      pools: PromiseOrValue<string>[],
      weights: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  _ve(overrides?: CallOverrides): Promise<string>;

  base(overrides?: CallOverrides): Promise<string>;

  bribes(
    gauge: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<string>;

  createGauge(
    pool: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  feeDistributers(
    gauge: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<string>;

  gauges(
    pool: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<string>;

  poolForGauge(
    gauge: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<string>;

  vote(
    tokenId: PromiseOrValue<BigNumberish>,
    pools: PromiseOrValue<string>[],
    weights: PromiseOrValue<BigNumberish>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    _ve(overrides?: CallOverrides): Promise<string>;

    base(overrides?: CallOverrides): Promise<string>;

    bribes(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<string>;

    createGauge(
      pool: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<string>;

    feeDistributers(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<string>;

    gauges(
      pool: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<string>;

    poolForGauge(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<string>;

    vote(
      tokenId: PromiseOrValue<BigNumberish>,
      pools: PromiseOrValue<string>[],
      weights: PromiseOrValue<BigNumberish>[],
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    _ve(overrides?: CallOverrides): Promise<BigNumber>;

    base(overrides?: CallOverrides): Promise<BigNumber>;

    bribes(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    createGauge(
      pool: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    feeDistributers(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    gauges(
      pool: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    poolForGauge(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    vote(
      tokenId: PromiseOrValue<BigNumberish>,
      pools: PromiseOrValue<string>[],
      weights: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    _ve(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    base(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    bribes(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    createGauge(
      pool: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    feeDistributers(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    gauges(
      pool: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    poolForGauge(
      gauge: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    vote(
      tokenId: PromiseOrValue<BigNumberish>,
      pools: PromiseOrValue<string>[],
      weights: PromiseOrValue<BigNumberish>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}