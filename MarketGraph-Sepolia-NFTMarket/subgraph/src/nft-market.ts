import { BigInt, Bytes } from "@graphprotocol/graph-ts"
import {
  NFTMarket,
  Listed,
  Canceled,
  Sold
} from "../generated/NFTMarket/NFTMarket"
import { List, Sold as SoldEntity } from "../generated/schema"

/**
 * @dev 处理 Listed 事件
 * 
 * 当 NFT 被上架时触发，创建新的 List 实体并保存所有上架信息
 * 
 * @param event Listed 事件对象
 */
export function handleListed(event: Listed): void {
  // 使用事件中的 id 作为 List 实体的唯一标识
  let list = new List(event.params.id)
  
  // 设置 List 实体的所有字段
  list.nft = event.params.nft
  list.tokenId = event.params.tokenId
  list.tokenURL = event.params.tokenURL
  list.seller = event.params.seller
  list.payToken = event.params.payToken
  list.price = event.params.price
  list.deadline = event.params.deadline
  
  // 区块信息
  list.blockNumber = event.block.number
  list.blockTimestamp = event.block.timestamp
  list.transactionHash = event.transaction.hash
  
  // 初始状态：未取消，未成交
  list.cancelTxHash = null
  list.filledTxHash = null
  
  // 保存到 Graph 数据库
  list.save()
}

/**
 * @dev 处理 Canceled 事件
 * 
 * 当上架被取消时触发，更新对应 List 实体的 cancelTxHash 字段
 * 
 * @param event Canceled 事件对象
 */
export function handleCanceled(event: Canceled): void {
  // 加载对应的 List 实体
  let list = List.load(event.params.id)
  
  // 如果 List 存在，更新 cancelTxHash
  if (list != null) {
    list.cancelTxHash = event.transaction.hash
    list.save()
  }
}

/**
 * @dev 处理 Sold 事件
 * 
 * 当 NFT 被购买时触发，执行以下操作：
 * 1. 创建新的 Sold 实体记录成交信息
 * 2. 更新对应 List 实体的 filledTxHash
 * 3. 建立 Sold 和 List 之间的关联
 * 
 * @param event Sold 事件对象
 */
export function handleSold(event: Sold): void {
  // 1. 创建 Sold 实体
  // 使用 transaction.hash 作为 Sold 的唯一标识
  let sold = new SoldEntity(event.transaction.hash)
  
  // 设置 Sold 实体的字段
  sold.buyer = event.params.buyer
  sold.fee = event.params.fee
  sold.blockNumber = event.block.number
  sold.blockTimestamp = event.block.timestamp
  sold.transactionHash = event.transaction.hash
  
  // 2. 建立与 List 的关联
  // 通过事件中的 id （上架 ID）关联到对应的 List
  sold.list = event.params.id.toHexString()
  
  // 保存 Sold 实体
  sold.save()
  
  // 3. 更新对应的 List 实体
  let list = List.load(event.params.id)
  if (list != null) {
    list.filledTxHash = event.transaction.hash
    list.save()
  }
}
