// Cloudflare API Response wrapper
export interface CFResponse<T = unknown> {
  result: T;
  success: boolean;
  errors: CFError[];
  messages: CFMessage[];
  result_info?: ResultInfo;
}

export interface CFError {
  code: number;
  message: string;
}

export interface CFMessage {
  code: number;
  message: string;
}

export interface ResultInfo {
  page: number;
  per_page: number;
  count: number;
  total_count: number;
  total_pages: number;
  cursor?: string;
}

// Zone
export interface Zone {
  id: string;
  name: string;
  status: "active" | "pending" | "initializing" | "moved" | "deleted" | "deactivated";
  plan: ZonePlan;
  name_servers: string[];
}

export interface ZonePlan {
  id: string;
  name: string;
  price: number;
  currency: string;
  frequency: string;
  is_subscribed: boolean;
}

// DNS Record
export interface DNSRecord {
  id: string;
  zone_id: string;
  zone_name: string;
  name: string;
  type: DNSType;
  content: string;
  proxiable: boolean;
  proxied: boolean;
  ttl: number;
  priority?: number;
  created_on: string;
  modified_on: string;
}

export type DNSType = "A" | "AAAA" | "CNAME" | "TXT" | "MX" | "NS" | "SRV" | "CAA" | "PTR" | "CERT" | "DNSKEY" | "DS" | "NAPTR" | "SMIMEA" | "SSHFP" | "SPF" | "TLSA" | "URI" | "HTTPS" | "SVCB";

// Worker
export interface WorkerScript {
  id: string;
  tag: string;
  etag: string;
  created_on: string;
  modified_on: string;
  usage_model: "bundled" | "unbound";
}

// Account
export interface Account {
  id: string;
  name: string;
  type: "standard" | "pro" | "business" | "enterprise";
}

// Common enums used across the app
export type ZoneStatus = Zone["status"];
export type UsageModel = WorkerScript["usage_model"];
export type AccountType = Account["type"];
