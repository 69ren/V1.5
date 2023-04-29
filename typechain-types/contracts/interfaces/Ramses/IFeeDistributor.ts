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

export interface IFeeDistributorInterface extends utils.Interface {
  functions: {
    "getReward(uint256,address[])": FunctionFragment;
    "getRewardTokens()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic: "getReward" | "getRewardTokens"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "getReward",
    values: [PromiseOrValue<BigNumberish>, PromiseOrValue<string>[]]
  ): string;
  encodeFunctionData(
    functionFragment: "getRewardTokens",
    values?: undefined
  ): string;

  decodeFunctionResult(functionFragment: "getReward", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getRewardTokens",
    data: BytesLike
  ): Result;

  events: {};
}

export interface IFeeDistributor extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: IFeeDistributorInterface;

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
    getReward(
      tokenId: PromiseOrValue<BigNumberish>,
      tokens: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    getRewardTokens(overrides?: CallOverrides): Promise<[string[]]>;
  };

  getReward(
    tokenId: PromiseOrValue<BigNumberish>,
    tokens: PromiseOrValue<string>[],
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  getRewardTokens(overrides?: CallOverrides): Promise<string[]>;

  callStatic: {
    getReward(
      tokenId: PromiseOrValue<BigNumberish>,
      tokens: PromiseOrValue<string>[],
      overrides?: CallOverrides
    ): Promise<void>;

    getRewardTokens(overrides?: CallOverrides): Promise<string[]>;
  };

  filters: {};

  estimateGas: {
    getReward(
      tokenId: PromiseOrValue<BigNumberish>,
      tokens: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    getRewardTokens(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    getReward(
      tokenId: PromiseOrValue<BigNumberish>,
      tokens: PromiseOrValue<string>[],
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    getRewardTokens(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}