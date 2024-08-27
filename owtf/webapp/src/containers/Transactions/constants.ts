import { API_BASE_URL } from "../../utils/constants";
export const TARGET_URL: string = `${API_BASE_URL}/targets/search/`;
export const TRANSACTIONS_URL: string = `${API_BASE_URL}/targets/target_id/transactions/search/`;
export const TRANSACTION_HEADER_URL: string = `${API_BASE_URL}/targets/target_id/transactions/transaction_id/`;
export const TRANSACTION_HRT_URL: string = `${API_BASE_URL}/targets/target_id/transactions/hrt/transaction_id/`;
export const TRANSACTION_API_URL: string = `${API_BASE_URL}/targets/target_id/transactions/`;
export const TRANSACTION_ZCONSOLE_URL: string = `${API_BASE_URL}/targets/target_id/transactions/zconsole`;

export const LOAD_TRANSACTIONS: string = "owtf/Transactions/LOAD_TRANSACTIONS",
  LOAD_TRANSACTIONS_SUCCESS: string =
    "owtf/Transactions/LOAD_TRANSACTIONS_SUCCESS",
  LOAD_TRANSACTIONS_ERROR: string = "owtf/Transactions/LOAD_TRANSACTIONS_ERROR";

export const LOAD_TRANSACTION: string = "owtf/Transactions/LOAD_TRANSACTION",
  LOAD_TRANSACTION_SUCCESS: string =
    "owtf/Transactions/LOAD_TRANSACTION_SUCCESS",
  LOAD_TRANSACTION_ERROR: string = "owtf/Transactions/LOAD_TRANSACTION_ERROR";

export const LOAD_HRT_RESPONSE: string = "owtf/Transactions/LOAD_HRT_RESPONSE",
  LOAD_HRT_RESPONSE_SUCCESS: string =
    "owtf/Transactions/LOAD_HRT_RESPONSE_SUCCESS",
  LOAD_HRT_RESPONSE_ERROR: string = "owtf/Transactions/LOAD_HRT_RESPONSE_ERROR";
