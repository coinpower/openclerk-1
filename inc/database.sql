-- needs MySQL 5.1
-- for MySQL 5.5, you can replace:
--    created_at datetime not null default now()
--    updated_at datetime not null default now() on update now()
-- and remove the update_at logic in the application
-- timestamp is also not y2038-compliant; datetime is up to y9999

DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id int not null auto_increment primary key,
  name varchar(255),
  openid_identity varchar(255) not null unique,
  email varchar(255),
  is_admin tinyint not null default 0,
  is_system tinyint not null default 0,
  created_at timestamp not null default current_timestamp,
  updated_at datetime,
  last_login datetime,

  is_premium tinyint not null default 0,
  premium_expires datetime,
  is_reminder_sent tinyint not null default 0,

  INDEX(openid_identity), INDEX(is_premium), INDEX(is_admin), INDEX(is_system)
);

INSERT INTO users SET id=100,name='System',openid_identity='http://openclerk.org/',email='support@openclerk.org',is_admin=0,is_system=1;

DROP TABLE IF EXISTS valid_user_keys;

CREATE TABLE valid_user_keys (
  id int not null auto_increment primary key,
  user_id int not null,
  user_key varchar(64) not null unique,
  created_at timestamp not null default current_timestamp,
  INDEX (user_id),
  INDEX (user_key)
);

-- recent uncaught exceptions
DROP TABLE IF EXISTS uncaught_exceptions;

CREATE TABLE uncaught_exceptions (
  id int not null auto_increment primary key,
  message varchar(255),
  previous_message varchar(255),
  filename varchar(255),
  line_number int,
  raw blob not null,
  class_name varchar(64),
  created_at timestamp not null default current_timestamp,

  job_id int, -- may have been generated as part of a job

  INDEX(job_id), INDEX(class_name)
);

-- OpenClerk information starts here

-- all of the different account types that users can have --

DROP TABLE IF EXISTS accounts_btce;

CREATE TABLE accounts_btce (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_poolx;

CREATE TABLE accounts_poolx (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_mtgox;

CREATE TABLE accounts_mtgox (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_vircurex;

CREATE TABLE accounts_vircurex (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_username varchar(255) not null,
  api_secret varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_litecoinglobal;

CREATE TABLE accounts_litecoinglobal (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- litecoinglobal has a range of securities; as we find new securities
-- (through users) we add these as normal queued jobs as well (using the securities user)
-- and can then use these to calculate balances. this however means that
-- we don't keep track of security counts/etc per user over time, just overall balance.

DROP TABLE IF EXISTS securities_litecoinglobal;

CREATE TABLE securities_litecoinglobal (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  name varchar(64) not null,

  INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_btct;

CREATE TABLE accounts_btct (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- same with btct

DROP TABLE IF EXISTS securities_btct;

CREATE TABLE securities_btct (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  name varchar(64) not null,

  INDEX(last_queue)
);

-- generic API requests

DROP TABLE IF EXISTS accounts_generic;

CREATE TABLE accounts_generic (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  currency varchar(3),
  api_url varchar(255) not null,

  INDEX(user_id), INDEX(currency), INDEX(last_queue)
);

-- all accounts (but not addresses) are summarised into balances

DROP TABLE IF EXISTS balances;

CREATE TABLE balances (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) not null, -- e.g. btce, btc, ltc, poolx, bitnz, generic, ...
  account_id int not null,
  -- we dont need to worry too much about precision
  balance decimal(16,8) not null,
  currency varchar(3) not null,
  is_recent tinyint not null default 0,

  INDEX(user_id), INDEX(exchange), INDEX(currency), INDEX(is_recent), INDEX(account_id)
);

-- all of the different crypto addresses that users can have, and their balances --

DROP TABLE IF EXISTS addresses;

CREATE TABLE addresses (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  currency varchar(3) not null,
  address varchar(36) not null,

  INDEX(currency), INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS address_balances;

CREATE TABLE address_balances (
  id int not null auto_increment primary key,
  user_id int not null,
  address_id int not null,
  created_at timestamp not null default current_timestamp,

  balance decimal(16,8) not null,
  is_recent tinyint not null default 0,

  INDEX(user_id), INDEX(address_id), INDEX(is_recent)
);

-- Litecoin explorer does not let you specify confirmations parameter,
-- so we need to keep track of current block number (stored locally
-- so we don't have to request Explorer twice)
DROP TABLE IF EXISTS litecoin_blocks;

CREATE TABLE litecoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- users can also specify offsets for non-API values --

DROP TABLE IF EXISTS offsets;

CREATE TABLE offsets (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,

  currency varchar(3) not null,
  balance decimal(16,8) not null,

  is_recent tinyint not null default 0,

  -- TODO titles/descriptions?

  INDEX(user_id), INDEX(currency), INDEX(is_recent)
);

-- all of the different exchanges that provide ticker data --

DROP TABLE IF EXISTS exchanges;

CREATE TABLE exchanges (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  name varchar(32) not null unique,
  last_queue datetime,
  -- this just stores last updated, not what currencies to download etc (defined in PHP)
  -- and also defines unique names for exchanges

  INDEX(last_queue), INDEX(name)
);

INSERT INTO exchanges SET name='btce';
INSERT INTO exchanges SET name='bitnz';
INSERT INTO exchanges SET name='mtgox';
INSERT INTO exchanges SET name='vircurex';

DROP TABLE IF EXISTS ticker;

CREATE TABLE ticker (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) not null, -- no point to have exchange_id, that's just extra queries

  currency1 varchar(3),
  currency2 varchar(3),

  -- we don't need to worry too much about precision
  last_trade decimal(16,8),
  buy decimal(16,8),
  sell decimal(16,8),
  volume decimal(16,8),

  is_recent tinyint not null default 0,

  -- derived indexes; rather than creating some query 'GROUP BY date_format(created_at, '%d-%m-%Y')',
  -- we can use a simple flag to mark daily data.
  -- only a single row with this index will ever be present for a single day.
  -- this same logic could be further composed into hourly/etc data.
  -- this field is updated when jobs are executed.
  is_daily_data tinyint not null default 0,

  INDEX(exchange), INDEX(currency1), INDEX(currency2), INDEX(is_recent), INDEX(is_daily_data)
);

-- and we want to provide summary data for users --

DROP TABLE IF EXISTS summaries;

CREATE TABLE summaries (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  summary_type varchar(32) not null,

  INDEX(summary_type), INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS summary_instances;

CREATE TABLE summary_instances (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  summary_type varchar(32) not null,

  is_recent tinyint not null default 0,

  -- we dont need to worry too much about precision
  balance decimal(16,8),

  -- derived indexes; rather than creating some query 'GROUP BY date_format(created_at, '%d-%m-%Y')',
  -- we can use a simple flag to mark daily data.
  -- only a single row with this index will ever be present for a single day.
  -- this same logic could be further composed into hourly/etc data.
  -- this field is updated when jobs are executed.
  is_daily_data tinyint not null default 0,

  INDEX(summary_type), INDEX(user_id), INDEX(is_recent), INDEX(is_daily_data)
);

-- to request data, we insert in jobs

DROP TABLE IF EXISTS jobs;

CREATE TABLE jobs (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  priority tinyint not null default 10, -- lower value = higher priority

  job_type varchar(32) not null,
  user_id int not null,   -- requesting user ID, may be system ID (100)
  arg_id int, -- argument for the job, a foreign key ID; may be null

  is_executed tinyint not null default 0,
  is_error tinyint not null default 0,    -- was an exception thrown while processing?

  executed_at datetime,

  INDEX(job_type), INDEX(priority), INDEX(user_id), INDEX(is_executed), INDEX(is_error)
);

-- users define graphs for their home page, split across pages

DROP TABLE IF EXISTS graph_pages;

CREATE TABLE graph_pages (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  updated_at datetime,
  user_id int not null,   -- requesting user ID, may be system ID (100)

  title varchar(64) not null,
  page_order tinyint default 0,       -- probably a good maximum number of pages, 256

  is_removed tinyint not null default 0,      -- not displayed; not deleted in case we want to undo

  INDEX(user_id), INDEX(is_removed)
);

DROP TABLE IF EXISTS graphs;

CREATE TABLE graphs (
  id int not null auto_increment primary key,
  page_id int not null,
  created_at timestamp not null default current_timestamp,

  graph_type varchar(32) not null,
  arg0 int,       -- some graphs have integer arguments
  width tinyint default 2,    -- e.g. 1 = half size, 2 = normal size, 4 = extra wide
  height tinyint default 2,
  page_order tinyint default 0,       -- probably a good maximum number of graphs, 256

  is_removed tinyint not null default 0,      -- not displayed; not deleted in case we want to undo

  INDEX(page_id), INDEX(is_removed)

);

-- premium account requests

DROP TABLE IF EXISTS outstanding_premiums;

CREATE TABLE outstanding_premiums (
  id int not null auto_increment primary key,
  user_id int not null,

  created_at timestamp not null default current_timestamp,
  paid_at datetime not null default 0,
  is_paid tinyint not null default 0,
  is_unpaid tinyint not null default 0,       -- this has never been paid after a very long time, so it's abandoned
  last_queue datetime,

  premium_address_id int not null, -- source address
  balance decimal(16,8),

  -- premium information
  months tinyint not null,
  years tinyint not null,

  -- we might as well reuse the existing infrastructure we have for checking address balances
  address_id int, -- target address in addresses

  INDEX(user_id), INDEX(address_id), INDEX(premium_address_id), INDEX(is_paid)
);

-- when making a new purchase, we add the address as an address to the System user,
-- which is then checked as normal. we can then check on the balance of that address
-- to find out when it has been paid.
DROP TABLE IF EXISTS premium_addresses;

CREATE TABLE premium_addresses (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  is_used tinyint not null default 0, -- i.e. is used in an outstanding_premiums
  used_at datetime,

  address varchar(36) not null,
  currency varchar(3) not null,

  INDEX(is_used), INDEX(currency)
);

-- keep track of external APIs; rather than pulling this from the database in real time, we
-- have a job that will regularly update this data. this data will be constant
-- outside of the update period.
DROP TABLE IF EXISTS external_status;

CREATE TABLE external_status (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  job_type varchar(32) not null,
  job_count int not null,
  job_errors int not null,
  job_first datetime not null,
  job_last datetime not null,
  sample_size int not null
);

-- updates since 0.1

-- eventually summary and ticker data is converted into a "graph" format
DROP TABLE IF EXISTS graph_data_ticker;

CREATE TABLE graph_data_ticker (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) not null, -- no point to have exchange_id, that's just extra queries

  currency1 varchar(3),
  currency2 varchar(3),

  -- currently all stored graph data is daily
  data_date timestamp not null,   -- the time of this day should be truncated to 0:00 UTC, representing the next 24 hours
  samples int not null,   -- how many samples was this data obtained from?

  buy decimal(16,8),  -- last buy of the day: preserves current behaviour
  sell decimal(16,8), -- last sell of the day: preserves current behaviour
  volume decimal(16,8),   -- maximum volume of the day

  -- for candlestick plots (eventually)
  last_trade_min decimal(16,8),
  last_trade_opening decimal(16,8),
  last_trade_closing decimal(16,8),
  last_trade_max decimal(16,8),

  INDEX(exchange), INDEX(currency1), INDEX(currency2), INDEX(data_date), UNIQUE(exchange, currency1, currency2, data_date)
);

DROP TABLE IF EXISTS graph_data_summary;

CREATE TABLE graph_data_summary (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  user_id int not null,
  summary_type varchar(32) not null,

  -- currently all stored graph data is daily
  data_date timestamp not null,   -- the time of this day should be truncated to 0:00 UTC, representing the next 24 hours
  samples int not null,   -- how many samples was this data obtained from?

  -- for candlestick plots (eventually)
  balance_min decimal(16,8),
  balance_opening decimal(16,8),
  balance_closing decimal(16,8),  -- also preserves current behaviour
  balance_max decimal(16,8),

  INDEX(user_id), INDEX(summary_type), INDEX(data_date), UNIQUE(user_id, summary_type, data_date)
);

-- in the future we could add graph_data_balances as necessary

-- all2btc is actually crypto2btc, since it doesn't consider fiat
UPDATE summary_instances SET summary_type='crypto2btc' WHERE summary_type='all2btc';

UPDATE graphs SET graph_type='total_converted_table' WHERE graph_type='fiat_converted_table';

-- --------------------------------------------------------------------------
-- upgrade statements from 0.1 to 0.2
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS feathercoin_blocks;

CREATE TABLE feathercoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

DROP TABLE IF EXISTS accounts_cryptostocks;

CREATE TABLE accounts_cryptostocks (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_email varchar(255) not null,
  api_key_coin varchar(255) not null,
  api_key_share varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- as per litecoinglobal/btct

DROP TABLE IF EXISTS securities_cryptostocks;

CREATE TABLE securities_cryptostocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  name varchar(64) not null,
  currency varchar(3),    -- only null until we've retrieved the security definition

  INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_slush;

CREATE TABLE accounts_slush (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_token varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_wemineltc;

CREATE TABLE accounts_wemineltc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_givemeltc;

CREATE TABLE accounts_givemeltc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.2 to 0.3
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS accounts_bips;

CREATE TABLE accounts_bips (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

ALTER TABLE graphs ADD days int;

DROP TABLE IF EXISTS accounts_btcguild;

CREATE TABLE accounts_btcguild (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_50btc;

CREATE TABLE accounts_50btc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

ALTER TABLE jobs ADD execution_count tinyint not null default 0;

-- update old jobs
UPDATE jobs SET execution_count=1 WHERE is_executed=1;

-- prevent POST DDoS of login page
CREATE TABLE heavy_requests (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  user_ip varchar(64) not null unique,    -- long string for IPv6, lets us block heavy requests based on IP
  last_request timestamp not null,

  INDEX(user_ip)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.3 to 0.4
-- --------------------------------------------------------------------------
CREATE TABLE graph_technicals (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  graph_id int not null,
  technical_type varchar(32) not null,        -- e.g. 'bollinger'
  technical_period tinyint,           -- e.g. 10

  INDEX(graph_id)
);

-- necessary for tax purposes
ALTER TABLE users ADD country varchar(4) not null;
ALTER TABLE users ADD user_ip varchar(64) not null; -- long string for IPv6

-- addresses can have titles
ALTER TABLE addresses ADD title varchar(255);

-- if a job takes more than <refresh> secs, we shouldn't be executing it simultaneously
ALTER TABLE jobs ADD is_executing tinyint not null default 0;
ALTER TABLE jobs ADD INDEX(is_executing);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.4 to 0.5
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS accounts_hypernova;

CREATE TABLE accounts_hypernova (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_ltcmineru;

CREATE TABLE accounts_ltcmineru (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- we now also summarise balance data
DROP TABLE IF EXISTS graph_data_balances;

CREATE TABLE graph_data_balances (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  user_id int not null,
  exchange varchar(32) not null,
  account_id int not null,
  currency varchar(3) not null,

  -- currently all stored graph data is daily
  data_date timestamp not null,   -- the time of this day should be truncated to 0:00 UTC, representing the next 24 hours
  samples int not null,   -- how many samples was this data obtained from?

  -- for candlestick plots (eventually)
  balance_min decimal(16,8),
  balance_opening decimal(16,8),
  balance_closing decimal(16,8),  -- also preserves current behaviour
  balance_max decimal(16,8),

  INDEX(user_id), INDEX(exchange), INDEX(data_date), UNIQUE(user_id, exchange, account_id, currency, data_date)
);

ALTER TABLE balances ADD is_daily_data tinyint not null default 0;
ALTER TABLE balances ADD INDEX(is_daily_data);

-- update existing balances with is_daily_data flag
UPDATE balances SET is_daily_data=0;
CREATE TABLE temp (id int not null, user_id int not null, exchange varchar(255) not null, currency varchar(6) not null, account_id int);
INSERT INTO temp (id, user_id, exchange, currency, account_id) SELECT MAX(id) AS id, user_id, exchange, currency, account_id FROM balances GROUP BY date_format(created_at, '%d-%m-%Y'), user_id, exchange, currency, account_id;
-- NOTE this can take a very long time to execute if there are many rows; this is because the entire dependent subquery is retrieved on every row
-- a much faster approach is to split up the execution into many smaller subtables:
--    CREATE TABLE temp2 (id int not null); INSERT INTO temp2 (SELECT id FROM temp WHERE id >= 0 AND id < (0 + 1000));
--    UPDATE balances SET is_daily_data=1 WHERE id >= 0 AND id < (0 + 1000) AND (id) IN (SELECT id FROM temp2);
--    DROP TABLE temp2;
-- (etc)
UPDATE balances SET is_daily_data=1 WHERE (id, user_id, exchange, currency, account_id) IN (SELECT * FROM temp);
DROP TABLE temp;

-- so we can debug failing balances etc
ALTER TABLE balances ADD job_id INT;
ALTER TABLE summary_instances ADD job_id INT;
ALTER TABLE ticker ADD job_id INT;

-- so that we calculate summaries - before conversions - as a whole, to prevent cases where all2btc relies on totalltc (which may have changed)
ALTER TABLE users ADD last_queue datetime;

-- these don't make any sense and will always be zero
DELETE FROM summary_instances WHERE summary_type='blockchainusd';
DELETE FROM summary_instances WHERE summary_type='blockchainnzd';
DELETE FROM summary_instances WHERE summary_type='blockchaineur';
DELETE FROM graph_data_summary WHERE summary_type='blockchainusd';
DELETE FROM graph_data_summary WHERE summary_type='blockchainnzd';
DELETE FROM graph_data_summary WHERE summary_type='blockchaineur';

-- rather than storing mining rates as balances, we store them in a separate table -
-- this makes it cleaner to do mining rate summaries per currency, without polluting the
-- balances table
DROP TABLE IF EXISTS hashrates;

CREATE TABLE hashrates (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) not null, -- e.g. btce, btc, ltc, poolx, bitnz, generic, ...
  account_id int not null,
  -- we dont need to worry too much about precision
  mhash float not null,       -- always in mhash
  currency varchar(3) not null,       -- e.g. slush will insert a btc and a nmc hashrate
  is_recent tinyint not null default 0,
  is_daily_data tinyint not null default 0,
  job_id int,

  INDEX(user_id), INDEX(exchange), INDEX(currency), INDEX(is_recent), INDEX(account_id), INDEX(is_daily_data)
);

-- precision isn't particularly important for stdev, since it's statistical anyway
ALTER TABLE graph_data_balances ADD balance_stdev float;
ALTER TABLE graph_data_summary ADD balance_stdev float;
ALTER TABLE graph_data_ticker ADD last_trade_stdev float;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.5 to 0.6
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
ALTER TABLE users ADD referer VARCHAR(255);

-- system-specific job queues that still need to be queued as appropriate
CREATE TABLE securities_update (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  exchange varchar(64) not null,

  INDEX(last_queue)
);

INSERT INTO securities_update SET exchange='btct';
INSERT INTO securities_update SET exchange='litecoinglobal';

-- so we have a history of external status
ALTER TABLE external_status ADD is_recent tinyint not null default 0;
ALTER TABLE external_status ADD INDEX(is_recent);

-- an integer index -> external API status table
CREATE TABLE external_status_types (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  job_type varchar(32) not null unique
);

-- technical_period can be > 128
ALTER TABLE graph_technicals MODIFY technical_period smallint;

DROP TABLE IF EXISTS accounts_miningforeman;

CREATE TABLE accounts_miningforeman (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_havelock;

CREATE TABLE accounts_havelock (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS securities_havelock;

CREATE TABLE securities_havelock (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  name varchar(64) not null,

  INDEX(last_queue)
);

INSERT INTO securities_update SET exchange='havelock';

-- we will remind the user regularly, up to a certain number of reminders, that this payment is overdue
ALTER TABLE outstanding_premiums ADD last_reminder datetime;
ALTER TABLE outstanding_premiums ADD cancelled_at datetime;

-- for automatically disabling users that have not logged in recently
ALTER TABLE users ADD is_disabled tinyint not null default 0;
ALTER TABLE users ADD INDEX(is_disabled);

ALTER TABLE users ADD disabled_at datetime;
ALTER TABLE users ADD disable_warned_at datetime;
ALTER TABLE users ADD is_disable_warned tinyint not null default 0;

-- because autologin never updated users last_login correctly, we'll give all old users the benefit of the doubt and say they've
-- logged in at the time of upgrade, so that old accounts are not all suddenly disabled
UPDATE users SET last_login=NOW();

-- periodically, create site statistics
DROP TABLE IF EXISTS site_statistics;
CREATE TABLE site_statistics (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  is_recent tinyint not null default 0,

  total_users int not null,
  disabled_users int not null,
  premium_users int not null,

  free_delay_minutes int not null,
  premium_delay_minutes int not null,
  outstanding_jobs int not null,
  external_status_job_count int not null, -- equal to 'sample_size'
  external_status_job_errors int not null,

  mysql_uptime int not null,      -- 'Uptime'
  mysql_threads int not null,     -- 'Threads_running'
  mysql_questions int not null,       -- 'Questions'
  mysql_slow_queries int not null,    -- 'Slow_queries'
  mysql_opens int not null,       -- 'Opened_tables'
  mysql_flush_tables int not null,    -- 'Flush_commands'
  mysql_open_tables int not null,     -- 'Open_tables'
  -- mysql_qps_average int not null, // can get qps = questions/uptime

  INDEX(is_recent)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.6 to 0.7
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

-- rather than using 'current balance' for payments, we should be using 'total received'
ALTER TABLE addresses ADD is_received tinyint not null default 0;

-- since we now handle partial payments, need to record how much was paid for each premium
ALTER TABLE outstanding_premiums ADD paid_balance decimal(16,8) default 0;
UPDATE outstanding_premiums SET paid_balance=balance WHERE is_paid=1;   -- update old data

DROP TABLE IF EXISTS ppcoin_blocks;

CREATE TABLE ppcoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

DROP TABLE IF EXISTS accounts_miningforeman_ftc;

CREATE TABLE accounts_miningforeman_ftc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- we now keep track of which securities each user has
-- but we don't yet keep track of is_daily_data etc, necessary for graphing quantities etc over time
DROP TABLE IF EXISTS securities;

CREATE TABLE securities (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) not null,      -- e.g. btct, litecoinglobal
  security_id int not null,       -- e.g. id from securites_btct

  quantity int not null,  -- assumes integer value
  is_recent tinyint not null default 0,

  INDEX(user_id), INDEX(exchange, security_id), INDEX(is_recent)
);

-- for 'heading' graph type
ALTER TABLE graphs ADD string0 varchar(128);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.7 to 0.8
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

ALTER TABLE site_statistics ADD system_load_1min int;
ALTER TABLE site_statistics ADD system_load_5min int;
ALTER TABLE site_statistics ADD system_load_15min int;

CREATE TABLE accounts_bitminter (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

CREATE TABLE accounts_mine_litecoin (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- rename all old securities balances to _wallet, since now we can track
-- wallets and balances separately
UPDATE balances SET exchange='btct_wallet' WHERE exchange='btct';
UPDATE balances SET exchange='litecoinglobal_wallet' WHERE exchange='litecoinglobal';
UPDATE balances SET exchange='cryptostocks_wallet' WHERE exchange='cryptostocks';
UPDATE balances SET exchange='havelock_wallet' WHERE exchange='havelock';

UPDATE graph_data_balances SET exchange='btct_wallet' WHERE exchange='btct';
UPDATE graph_data_balances SET exchange='litecoinglobal_wallet' WHERE exchange='litecoinglobal';
UPDATE graph_data_balances SET exchange='cryptostocks_wallet' WHERE exchange='cryptostocks';
UPDATE graph_data_balances SET exchange='havelock_wallet' WHERE exchange='havelock';

CREATE TABLE accounts_liteguardian (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- fiat currency data from themoneyconverter.com
INSERT INTO exchanges SET name='themoneyconverter';

-- CAD/BTC
INSERT INTO exchanges SET name='virtex';

-- USD/BTC
INSERT INTO exchanges SET name='bitstamp';

-- --------------------------------------------------------------------------
-- upgrade statements from 0.8 to 0.9
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

-- LTC, FTC, BTC all use the same API key
DROP TABLE IF EXISTS accounts_givemecoins;

CREATE TABLE accounts_givemecoins (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- set all old givemeltc balances to 0, so that they don't interfere with our summary calculations
UPDATE balances SET balance=0 WHERE exchange='givemeltc' AND is_recent=1;
UPDATE hashrates SET mhash=0 WHERE exchange='givemeltc' AND is_recent=1;

-- we can actually copy these over
INSERT INTO accounts_givemecoins (user_id, created_at, last_queue, title, api_key) (SELECT user_id, created_at, last_queue, title, api_key FROM accounts_givemeltc);

-- disable old mine_litecoin balances
UPDATE balances SET balance=0 WHERE exchange='mine_litecoin' AND is_recent=1;
UPDATE hashrates SET mhash=0 WHERE exchange='mine_litecoin' AND is_recent=1;

-- managed graph functionality
ALTER TABLE users ADD graph_managed_type varchar(16) not null default 'none';   -- 'none', 'auto', 'preferences'
ALTER TABLE users ADD INDEX(graph_managed_type);
ALTER TABLE users ADD preferred_crypto varchar(3) not null default 'btc';   -- preferred cryptocurrency
ALTER TABLE users ADD preferred_fiat varchar(3) not null default 'usd'; -- preferred fiat currency

ALTER TABLE users ADD needs_managed_update tinyint not null default 0;  -- graph_managed_type = auto or managed, and we need to update our graphs on next profile load

-- graph management preferences
CREATE TABLE managed_graphs (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,

  preference varchar(32) not null,

  INDEX(user_id)
);

-- was this graph added automatically?
ALTER TABLE graphs ADD is_managed tinyint not null default 0;
ALTER TABLE graph_pages ADD is_managed tinyint not null default 0;

ALTER TABLE graphs ADD INDEX(is_managed);
ALTER TABLE graph_pages ADD INDEX(is_managed);

-- page_order can be < 9000 due to managed graphs
-- (alternatively we could write complicated logic to reorder new & existing graphs based on their intended order)
ALTER TABLE graphs MODIFY page_order smallint default 0;

-- rename summary_nzd to summary_nzd_bitnz to fix wizard bug
UPDATE summaries SET summary_type='summary_nzd_bitnz' WHERE summary_type='summary_nzd';
UPDATE summary_instances SET summary_type='all2nzd_bitnz' WHERE summary_type='all2nzd';
UPDATE graph_data_summary SET summary_type='all2nzd_bitnz' WHERE summary_type='all2nzd';
UPDATE graphs SET graph_type='all2nzd_bitnz_daily' WHERE graph_type='all2nzd_daily';

ALTER TABLE users ADD last_managed_update datetime;

-- new signup form: 'subscribe to site announcements' field
ALTER TABLE users ADD subscribe_announcements tinyint not null default 0;

-- new subscriptions/unsubscriptions will be placed in here, so that they
-- can be processed manually (since google groups doesn't have an API)
CREATE TABLE pending_subscriptions (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,

  is_subscribe tinyint not null default 0,

  INDEX(user_id)
);

-- fields to send users a message when their first reports have been completed
-- (and, eventually into automated emails)
ALTER TABLE users ADD last_report_queue datetime;
ALTER TABLE users ADD is_first_report_sent tinyint not null default 0;
ALTER TABLE users ADD INDEX(is_first_report_sent);

-- all old users will not receive a first report
UPDATE users SET is_first_report_sent=1 WHERE DATE_ADD(created_at, INTERVAL 1 DAY) < NOW();

-- BitFunder publishes all asset owners to a public .json file, so
-- we only have to request this file once per hour (as per premium users)
INSERT INTO securities_update SET exchange='bitfunder';

DROP TABLE IF EXISTS securities_bitfunder;

CREATE TABLE securities_bitfunder (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  name varchar(64) not null,

  INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_bitfunder;

CREATE TABLE accounts_bitfunder (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  btc_address varchar(64) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- more site statistics
ALTER TABLE site_statistics ADD users_graphs_managed_none int;
ALTER TABLE site_statistics ADD users_graphs_managed_managed int;
ALTER TABLE site_statistics ADD users_graphs_managed_auto int;
ALTER TABLE site_statistics ADD users_graphs_need_update int;
ALTER TABLE site_statistics ADD users_subscribe_announcements int;
ALTER TABLE site_statistics ADD pending_subscriptions int;
ALTER TABLE site_statistics ADD pending_unsubscriptions int;

ALTER TABLE users ADD logins_after_disable_warned tinyint not null default 0;   -- not just a switch, but a count
ALTER TABLE site_statistics ADD user_logins_after_warned int;   -- total count
ALTER TABLE site_statistics ADD users_login_after_warned int;   -- total users
ALTER TABLE users ADD logins_after_disabled tinyint not null default 0; -- not just a switch, but a count
ALTER TABLE site_statistics ADD user_logins_after_disabled int; -- total count
ALTER TABLE site_statistics ADD users_login_after_disabled int; -- total users

ALTER TABLE site_statistics MODIFY system_load_1min float;
ALTER TABLE site_statistics MODIFY system_load_5min float;
ALTER TABLE site_statistics MODIFY system_load_15min float;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.9 to 0.10
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS novacoin_blocks;

CREATE TABLE novacoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- drop old tables
DROP TABLE IF EXISTS accounts_givemeltc;
DROP TABLE IF EXISTS accounts_mine_litecoin;

DROP TABLE IF EXISTS accounts_khore;

CREATE TABLE accounts_khore (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- for privately-held securities
CREATE TABLE accounts_individual_litecoinglobal (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  quantity int not null,
  security_id int not null,   -- to securities_litecoinglobal

  INDEX(user_id), INDEX(last_queue), INDEX(security_id)
);

CREATE TABLE accounts_individual_btct (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  quantity int not null,
  security_id int not null,   -- to securities_btct

  INDEX(user_id), INDEX(last_queue), INDEX(security_id)
);

CREATE TABLE accounts_individual_bitfunder (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  quantity int not null,
  security_id int not null,   -- to securities_bitfunder

  INDEX(user_id), INDEX(last_queue), INDEX(security_id)
);

CREATE TABLE accounts_individual_cryptostocks (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  quantity int not null,
  security_id int not null,   -- to securities_cryptostocks

  INDEX(user_id), INDEX(last_queue), INDEX(security_id)
);

CREATE TABLE accounts_individual_havelock (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  quantity int not null,
  security_id int not null,   -- to securities_havelock

  INDEX(user_id), INDEX(last_queue), INDEX(security_id)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.10 to 0.11
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
DROP TABLE IF EXISTS accounts_cexio;

CREATE TABLE accounts_cexio (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,
  api_username varchar(255) not null,
  api_secret varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

INSERT INTO exchanges SET name='cexio';

INSERT INTO exchanges SET name='crypto-trade';

DROP TABLE IF EXISTS accounts_cryptotrade;

CREATE TABLE accounts_cryptotrade (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS securities_cryptotrade;

CREATE TABLE securities_cryptotrade (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  name varchar(64) not null,
  currency varchar(4) not null,

  INDEX(last_queue)
);

-- we insert these securities manually for now
INSERT INTO securities_cryptotrade SET name='CTB', currency='btc';
INSERT INTO securities_cryptotrade SET name='CTL', currency='ltc';
INSERT INTO securities_cryptotrade SET name='ESB', currency='btc';
INSERT INTO securities_cryptotrade SET name='ESL', currency='ltc';

CREATE TABLE accounts_individual_cryptotrade (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  quantity int not null,
  security_id int not null,   -- to securities_cryptotrade

  INDEX(user_id), INDEX(last_queue), INDEX(security_id)
);

-- performance improvements due to MySQL slow queries log
ALTER TABLE securities_bitfunder ADD index(name);
ALTER TABLE securities_btct ADD index(name);
ALTER TABLE securities_cryptostocks ADD index(name);
ALTER TABLE securities_cryptotrade ADD index(name);
ALTER TABLE securities_havelock ADD index(name);
ALTER TABLE securities_litecoinglobal ADD index(name);

-- since wizard_addresses always searches for the most recent job for a given address,
-- adding an is_recent/is_archived flag will allow us to reduce the search set significantly
ALTER TABLE jobs ADD is_recent tinyint not null default 0;
ALTER TABLE jobs ADD INDEX(is_recent);

-- mark all jobs in the last 24 hours as recent; batch_run will eventually sort everything out
-- (this is better than freezing the production database with a very complex but correct query)
UPDATE jobs SET is_recent=1 WHERE is_executed=1 AND is_recent=0 AND executed_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR);

-- allow users to trigger tests
ALTER TABLE jobs ADD is_test_job tinyint not null default 0;
ALTER TABLE jobs ADD INDEX(is_test_job);

-- for jobs that timeout
ALTER TABLE jobs ADD execution_started timestamp null;
ALTER TABLE jobs ADD is_timeout tinyint not null default 0;
ALTER TABLE jobs ADD INDEX(is_timeout);

ALTER TABLE site_statistics ADD jobs_tests int not null default 0;
ALTER TABLE site_statistics ADD jobs_timeout int not null default 0;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.11 to 0.12
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

-- all date columns should be timestamp not datetime, so that all values are stored local to UTC
ALTER TABLE accounts_50btc MODIFY last_queue timestamp null;
ALTER TABLE accounts_bips MODIFY last_queue timestamp null;
ALTER TABLE accounts_bitfunder MODIFY last_queue timestamp null;
ALTER TABLE accounts_bitminter MODIFY last_queue timestamp null;
ALTER TABLE accounts_btce MODIFY last_queue timestamp null;
ALTER TABLE accounts_btcguild MODIFY last_queue timestamp null;
ALTER TABLE accounts_btct MODIFY last_queue timestamp null;
ALTER TABLE accounts_cexio MODIFY last_queue timestamp null;
ALTER TABLE accounts_cryptostocks MODIFY last_queue timestamp null;
ALTER TABLE accounts_cryptotrade MODIFY last_queue timestamp null;
ALTER TABLE accounts_generic MODIFY last_queue timestamp null;
ALTER TABLE accounts_givemecoins MODIFY last_queue timestamp null;
ALTER TABLE accounts_havelock MODIFY last_queue timestamp null;
ALTER TABLE accounts_hypernova MODIFY last_queue timestamp null;
ALTER TABLE accounts_individual_bitfunder MODIFY last_queue timestamp null;
ALTER TABLE accounts_individual_btct MODIFY last_queue timestamp null;
ALTER TABLE accounts_individual_cryptostocks MODIFY last_queue timestamp null;
ALTER TABLE accounts_individual_cryptotrade MODIFY last_queue timestamp null;
ALTER TABLE accounts_individual_havelock MODIFY last_queue timestamp null;
ALTER TABLE accounts_individual_litecoinglobal MODIFY last_queue timestamp null;
ALTER TABLE accounts_khore MODIFY last_queue timestamp null;
ALTER TABLE accounts_litecoinglobal MODIFY last_queue timestamp null;
ALTER TABLE accounts_liteguardian MODIFY last_queue timestamp null;
ALTER TABLE accounts_ltcmineru MODIFY last_queue timestamp null;
ALTER TABLE accounts_miningforeman MODIFY last_queue timestamp null;
ALTER TABLE accounts_miningforeman_ftc MODIFY last_queue timestamp null;
ALTER TABLE accounts_mtgox MODIFY last_queue timestamp null;
ALTER TABLE accounts_poolx MODIFY last_queue timestamp null;
ALTER TABLE accounts_slush MODIFY last_queue timestamp null;
ALTER TABLE accounts_vircurex MODIFY last_queue timestamp null;
ALTER TABLE accounts_wemineltc MODIFY last_queue timestamp null;
ALTER TABLE addresses MODIFY last_queue timestamp null;
ALTER TABLE exchanges MODIFY last_queue timestamp null;
ALTER TABLE external_status MODIFY job_first timestamp not null;
ALTER TABLE external_status MODIFY job_last timestamp not null;
ALTER TABLE graph_pages MODIFY updated_at timestamp null;
ALTER TABLE jobs MODIFY executed_at timestamp null;
ALTER TABLE outstanding_premiums MODIFY paid_at timestamp null;
ALTER TABLE outstanding_premiums MODIFY last_queue timestamp null;
ALTER TABLE outstanding_premiums MODIFY last_reminder timestamp null;
ALTER TABLE outstanding_premiums MODIFY cancelled_at timestamp null;
ALTER TABLE premium_addresses MODIFY used_at timestamp null;
ALTER TABLE securities_bitfunder MODIFY last_queue timestamp null;
ALTER TABLE securities_btct MODIFY last_queue timestamp null;
ALTER TABLE securities_cryptostocks MODIFY last_queue timestamp null;
ALTER TABLE securities_cryptotrade MODIFY last_queue timestamp null;
ALTER TABLE securities_havelock MODIFY last_queue timestamp null;
ALTER TABLE securities_litecoinglobal MODIFY last_queue timestamp null;
ALTER TABLE securities_update MODIFY last_queue timestamp null;
ALTER TABLE summaries MODIFY last_queue timestamp null;
ALTER TABLE users MODIFY updated_at timestamp null;
ALTER TABLE users MODIFY last_login timestamp null;
ALTER TABLE users MODIFY premium_expires timestamp null;
ALTER TABLE users MODIFY last_queue timestamp null;
ALTER TABLE users MODIFY disabled_at timestamp null;
ALTER TABLE users MODIFY disable_warned_at timestamp null;
ALTER TABLE users MODIFY last_managed_update timestamp null;
ALTER TABLE users MODIFY last_report_queue timestamp null;

-- add new site_space statistics
ALTER TABLE site_statistics ADD disk_free_space float;  -- precision isn't strictly necessary

-- remove orphaned _securities and _wallet balances
DELETE FROM balances WHERE exchange='litecoinglobal_securities' AND account_id NOT IN (SELECT id FROM accounts_litecoinglobal);
DELETE FROM balances WHERE exchange='litecoinglobal_wallet' AND account_id NOT IN (SELECT id FROM accounts_litecoinglobal);
DELETE FROM balances WHERE exchange='btct_securities' AND account_id NOT IN (SELECT id FROM accounts_btct);
DELETE FROM balances WHERE exchange='btct_wallet' AND account_id NOT IN (SELECT id FROM accounts_btct);
DELETE FROM balances WHERE exchange='crypto-trade_securities' AND account_id NOT IN (SELECT id FROM accounts_cryptotrade);
DELETE FROM balances WHERE exchange='crypto-trade_wallet' AND account_id NOT IN (SELECT id FROM accounts_cryptotrade);
DELETE FROM balances WHERE exchange='cryptostocks_securities' AND account_id NOT IN (SELECT id FROM accounts_cryptostocks);
DELETE FROM balances WHERE exchange='cryptostocks_wallet' AND account_id NOT IN (SELECT id FROM accounts_cryptostocks);
DELETE FROM balances WHERE exchange='havelock_securities' AND account_id NOT IN (SELECT id FROM accounts_havelock);
DELETE FROM balances WHERE exchange='havelock_wallet' AND account_id NOT IN (SELECT id FROM accounts_havelock);
DELETE FROM balances WHERE exchange='bitfunder_securities' AND account_id NOT IN (SELECT id FROM accounts_bitfunder);

-- database cleanup
DELETE FROM ticker WHERE currency1='nzd' AND currency2='btc' AND last_trade=0;
CREATE TABLE temp (id int);
INSERT INTO temp (SELECT user_id FROM summary_instances WHERE summary_type='all2nzd_bitnz' AND balance > 0 GROUP BY user_id);
DELETE FROM summary_instances WHERE summary_type='all2nzd_bitnz' AND balance=0 AND user_id IN (SELECT id FROM temp);
DROP TABLE temp;

-- track time between account creation and first report ready
ALTER TABLE users ADD first_report_sent timestamp null;
ALTER TABLE users ADD reminder_sent timestamp null;

DROP TABLE IF EXISTS accounts_bitstamp;

CREATE TABLE accounts_bitstamp (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_client_id int not null,
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

DROP TABLE IF EXISTS accounts_796;

CREATE TABLE accounts_796 (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_app_id int not null,
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- 796 doesn't have an API for listing securities or their names, so we enter them in manually

DROP TABLE IF EXISTS securities_796;

CREATE TABLE securities_796 (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp null,

  name varchar(64) not null,
  title varchar(64) not null,
  api_name varchar(64) not null,      -- because 'mri's API name is 'xchange' instead

  INDEX(last_queue)
);
INSERT INTO securities_796 SET name='mri', title='796Xchange-MRI', api_name='xchange';
INSERT INTO securities_796 SET name='asicminer', title='ASICMINER-796', api_name='asicminer';
INSERT INTO securities_796 SET name='bd', title='BTC-DICE-796', api_name='bd';

CREATE TABLE accounts_individual_796 (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  quantity int not null,
  security_id int not null,   -- to securities_796

  INDEX(user_id), INDEX(last_queue), INDEX(security_id)
);

ALTER TABLE users ADD securities_count int not null default 0;
ALTER TABLE users ADD securities_last_count_queue timestamp null;

DROP TABLE IF EXISTS accounts_kattare;

CREATE TABLE accounts_kattare (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp null,

  title varchar(255),
  api_key varchar(255) not null,

  INDEX(user_id), INDEX(last_queue)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.12 to 0.13
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

-- accounts can now be disabled if they fail repeatedly
-- failing account tables need to have the following fields: is_disabled, failures, first_failure, title
-- and set 'failures' to true in account_data_grouped()
ALTER TABLE accounts_bitstamp ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_bitstamp ADD failures tinyint not null default 0;
ALTER TABLE accounts_bitstamp ADD first_failure timestamp null;
ALTER TABLE accounts_bitstamp ADD INDEX(is_disabled);

ALTER TABLE accounts_50btc ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_50btc ADD failures tinyint not null default 0;
ALTER TABLE accounts_50btc ADD first_failure timestamp null;
ALTER TABLE accounts_50btc ADD INDEX(is_disabled);

ALTER TABLE accounts_796 ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_796 ADD failures tinyint not null default 0;
ALTER TABLE accounts_796 ADD first_failure timestamp null;
ALTER TABLE accounts_796 ADD INDEX(is_disabled);

ALTER TABLE accounts_bips ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_bips ADD failures tinyint not null default 0;
ALTER TABLE accounts_bips ADD first_failure timestamp null;
ALTER TABLE accounts_bips ADD INDEX(is_disabled);

ALTER TABLE accounts_bitfunder ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_bitfunder ADD failures tinyint not null default 0;
ALTER TABLE accounts_bitfunder ADD first_failure timestamp null;
ALTER TABLE accounts_bitfunder ADD INDEX(is_disabled);

ALTER TABLE accounts_bitminter ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_bitminter ADD failures tinyint not null default 0;
ALTER TABLE accounts_bitminter ADD first_failure timestamp null;
ALTER TABLE accounts_bitminter ADD INDEX(is_disabled);

ALTER TABLE accounts_btce ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_btce ADD failures tinyint not null default 0;
ALTER TABLE accounts_btce ADD first_failure timestamp null;
ALTER TABLE accounts_btce ADD INDEX(is_disabled);

ALTER TABLE accounts_btcguild ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_btcguild ADD failures tinyint not null default 0;
ALTER TABLE accounts_btcguild ADD first_failure timestamp null;
ALTER TABLE accounts_btcguild ADD INDEX(is_disabled);

ALTER TABLE accounts_btct ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_btct ADD failures tinyint not null default 0;
ALTER TABLE accounts_btct ADD first_failure timestamp null;
ALTER TABLE accounts_btct ADD INDEX(is_disabled);

ALTER TABLE accounts_cexio ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_cexio ADD failures tinyint not null default 0;
ALTER TABLE accounts_cexio ADD first_failure timestamp null;
ALTER TABLE accounts_cexio ADD INDEX(is_disabled);

ALTER TABLE accounts_cryptostocks ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_cryptostocks ADD failures tinyint not null default 0;
ALTER TABLE accounts_cryptostocks ADD first_failure timestamp null;
ALTER TABLE accounts_cryptostocks ADD INDEX(is_disabled);

ALTER TABLE accounts_cryptotrade ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_cryptotrade ADD failures tinyint not null default 0;
ALTER TABLE accounts_cryptotrade ADD first_failure timestamp null;
ALTER TABLE accounts_cryptotrade ADD INDEX(is_disabled);

ALTER TABLE accounts_generic ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_generic ADD failures tinyint not null default 0;
ALTER TABLE accounts_generic ADD first_failure timestamp null;
ALTER TABLE accounts_generic ADD INDEX(is_disabled);

ALTER TABLE accounts_givemecoins ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_givemecoins ADD failures tinyint not null default 0;
ALTER TABLE accounts_givemecoins ADD first_failure timestamp null;
ALTER TABLE accounts_givemecoins ADD INDEX(is_disabled);

ALTER TABLE accounts_havelock ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_havelock ADD failures tinyint not null default 0;
ALTER TABLE accounts_havelock ADD first_failure timestamp null;
ALTER TABLE accounts_havelock ADD INDEX(is_disabled);

ALTER TABLE accounts_hypernova ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_hypernova ADD failures tinyint not null default 0;
ALTER TABLE accounts_hypernova ADD first_failure timestamp null;
ALTER TABLE accounts_hypernova ADD INDEX(is_disabled);

ALTER TABLE accounts_kattare ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_kattare ADD failures tinyint not null default 0;
ALTER TABLE accounts_kattare ADD first_failure timestamp null;
ALTER TABLE accounts_kattare ADD INDEX(is_disabled);

ALTER TABLE accounts_khore ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_khore ADD failures tinyint not null default 0;
ALTER TABLE accounts_khore ADD first_failure timestamp null;
ALTER TABLE accounts_khore ADD INDEX(is_disabled);

ALTER TABLE accounts_litecoinglobal ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_litecoinglobal ADD failures tinyint not null default 0;
ALTER TABLE accounts_litecoinglobal ADD first_failure timestamp null;
ALTER TABLE accounts_litecoinglobal ADD INDEX(is_disabled);

ALTER TABLE accounts_liteguardian ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_liteguardian ADD failures tinyint not null default 0;
ALTER TABLE accounts_liteguardian ADD first_failure timestamp null;
ALTER TABLE accounts_liteguardian ADD INDEX(is_disabled);

ALTER TABLE accounts_ltcmineru ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_ltcmineru ADD failures tinyint not null default 0;
ALTER TABLE accounts_ltcmineru ADD first_failure timestamp null;
ALTER TABLE accounts_ltcmineru ADD INDEX(is_disabled);

ALTER TABLE accounts_miningforeman ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_miningforeman ADD failures tinyint not null default 0;
ALTER TABLE accounts_miningforeman ADD first_failure timestamp null;
ALTER TABLE accounts_miningforeman ADD INDEX(is_disabled);

ALTER TABLE accounts_miningforeman_ftc ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_miningforeman_ftc ADD failures tinyint not null default 0;
ALTER TABLE accounts_miningforeman_ftc ADD first_failure timestamp null;
ALTER TABLE accounts_miningforeman_ftc ADD INDEX(is_disabled);

ALTER TABLE accounts_mtgox ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_mtgox ADD failures tinyint not null default 0;
ALTER TABLE accounts_mtgox ADD first_failure timestamp null;
ALTER TABLE accounts_mtgox ADD INDEX(is_disabled);

ALTER TABLE accounts_poolx ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_poolx ADD failures tinyint not null default 0;
ALTER TABLE accounts_poolx ADD first_failure timestamp null;
ALTER TABLE accounts_poolx ADD INDEX(is_disabled);

ALTER TABLE accounts_slush ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_slush ADD failures tinyint not null default 0;
ALTER TABLE accounts_slush ADD first_failure timestamp null;
ALTER TABLE accounts_slush ADD INDEX(is_disabled);

ALTER TABLE accounts_vircurex ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_vircurex ADD failures tinyint not null default 0;
ALTER TABLE accounts_vircurex ADD first_failure timestamp null;
ALTER TABLE accounts_vircurex ADD INDEX(is_disabled);

ALTER TABLE accounts_wemineltc ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_wemineltc ADD failures tinyint not null default 0;
ALTER TABLE accounts_wemineltc ADD first_failure timestamp null;
ALTER TABLE accounts_wemineltc ADD INDEX(is_disabled);

INSERT INTO exchanges SET name='btcchina';

INSERT INTO exchanges SET name='cryptsy';

DROP TABLE IF EXISTS accounts_litepooleu;

CREATE TABLE accounts_litepooleu (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_coinhuntr;

CREATE TABLE accounts_coinhuntr (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_eligius;

CREATE TABLE accounts_eligius (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  btc_address varchar(64) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- for tracking unpaid balances on Eligius accounts
INSERT INTO securities_update SET exchange='eligius';

DROP TABLE IF EXISTS accounts_lite_coinpool;

CREATE TABLE accounts_lite_coinpool (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS primecoin_blocks;

CREATE TABLE primecoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.13 to 0.13.1
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

-- allow securities_havelock accounts to be disabled automatically
ALTER TABLE securities_havelock ADD is_disabled tinyint not null default 0;
ALTER TABLE securities_havelock ADD failures tinyint not null default 0;
ALTER TABLE securities_havelock ADD first_failure timestamp null;
ALTER TABLE securities_havelock ADD INDEX(is_disabled);

-- fix Eligius pool hashrates measuring in BTC not LTC
UPDATE hashrates SET currency='btc' WHERE exchange='eligius' AND currency='ltc';

-- 'sum' job now executes all summaries
ALTER TABLE summaries DROP last_queue;
DELETE FROM jobs WHERE job_type='summary' AND is_executed=0;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.13.1 to 0.14
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

-- make individual securities support failures
ALTER TABLE accounts_individual_796 ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_individual_796 ADD failures tinyint not null default 0;
ALTER TABLE accounts_individual_796 ADD first_failure timestamp null;
ALTER TABLE accounts_individual_796 ADD INDEX(is_disabled);

ALTER TABLE accounts_individual_bitfunder ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_individual_bitfunder ADD failures tinyint not null default 0;
ALTER TABLE accounts_individual_bitfunder ADD first_failure timestamp null;
ALTER TABLE accounts_individual_bitfunder ADD INDEX(is_disabled);

ALTER TABLE accounts_individual_btct ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_individual_btct ADD failures tinyint not null default 0;
ALTER TABLE accounts_individual_btct ADD first_failure timestamp null;
ALTER TABLE accounts_individual_btct ADD INDEX(is_disabled);

ALTER TABLE accounts_individual_cryptostocks ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_individual_cryptostocks ADD failures tinyint not null default 0;
ALTER TABLE accounts_individual_cryptostocks ADD first_failure timestamp null;
ALTER TABLE accounts_individual_cryptostocks ADD INDEX(is_disabled);

ALTER TABLE accounts_individual_cryptotrade ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_individual_cryptotrade ADD failures tinyint not null default 0;
ALTER TABLE accounts_individual_cryptotrade ADD first_failure timestamp null;
ALTER TABLE accounts_individual_cryptotrade ADD INDEX(is_disabled);

ALTER TABLE accounts_individual_havelock ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_individual_havelock ADD failures tinyint not null default 0;
ALTER TABLE accounts_individual_havelock ADD first_failure timestamp null;
ALTER TABLE accounts_individual_havelock ADD INDEX(is_disabled);

ALTER TABLE accounts_individual_litecoinglobal ADD is_disabled tinyint not null default 0;
ALTER TABLE accounts_individual_litecoinglobal ADD failures tinyint not null default 0;
ALTER TABLE accounts_individual_litecoinglobal ADD first_failure timestamp null;
ALTER TABLE accounts_individual_litecoinglobal ADD INDEX(is_disabled);

-- removing bitfunder
DELETE FROM securities_update WHERE exchange='bitfunder';
UPDATE accounts_bitfunder SET is_disabled=1;
UPDATE accounts_individual_bitfunder SET is_disabled=1;

DROP TABLE IF EXISTS terracoin_blocks;

CREATE TABLE terracoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- admin messages (for now, just for version_checks)
CREATE TABLE admin_messages (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  message_type varchar(32) not null,
  message varchar(255) not null,      -- NOTE must be htmlspecialchars() as necessary!

  is_read tinyint not null default 0,

  INDEX(is_read), INDEX(message_type)
);

DROP TABLE IF EXISTS accounts_beeeeer;

CREATE TABLE accounts_beeeeer (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  xpm_address varchar(64) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- remember this is different from accounts_lite_coinpool
DROP TABLE IF EXISTS accounts_litecoinpool;

CREATE TABLE accounts_litecoinpool (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.14 to 0.15
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

-- when deleting BTCT/etc accounts, the securities still display
ALTER TABLE securities ADD account_id int null default 0;
ALTER TABLE securities ADD INDEX(account_id);

-- this will mean up to 0.15, all securities will not have a parent - but as soon as
-- accounts refresh, they will be readded with a parent
-- (this will also hide old deleted securities from the Your Securities page)
UPDATE securities SET is_recent=0 WHERE account_id=0;
UPDATE accounts_796 SET last_queue=DATE_SUB(last_queue, INTERVAL 1 DAY);
UPDATE accounts_btct SET last_queue=DATE_SUB(last_queue, INTERVAL 1 DAY);
UPDATE accounts_cryptotrade SET last_queue=DATE_SUB(last_queue, INTERVAL 1 DAY);
UPDATE accounts_cryptostocks SET last_queue=DATE_SUB(last_queue, INTERVAL 1 DAY);
UPDATE accounts_havelock SET last_queue=DATE_SUB(last_queue, INTERVAL 1 DAY);
UPDATE accounts_litecoinglobal SET last_queue=DATE_SUB(last_queue, INTERVAL 1 DAY);

-- users can now have multiple OpenID identities per account
CREATE TABLE openid_identities (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  url varchar(255) not null,

  INDEX(user_id), INDEX(url)
);

-- merge existing user identities
INSERT INTO openid_identities (user_id, url, created_at) (SELECT id AS user_id, openid_identity AS url, created_at FROM users);

-- remove old identities
ALTER TABLE users DROP openid_identity;

-- users can disable automatic graph refresh
ALTER TABLE users ADD disable_graph_refresh tinyint not null default 0;

INSERT INTO exchanges SET name='coins-e';

-- adding support for dogecoin
-- dogecoin supports up to 100 billion (100,000,000,000) with 8 dp, and volume
-- can be higher than this, therefore need higher precision (at least 12+8)
ALTER TABLE balances MODIFY balance decimal(24,8) not null;
ALTER TABLE address_balances MODIFY balance decimal(24,8) not null;
ALTER TABLE offsets MODIFY balance decimal(24,8) not null;
ALTER TABLE ticker MODIFY last_trade decimal(24,8);
ALTER TABLE ticker MODIFY buy decimal(24,8);
ALTER TABLE ticker MODIFY sell decimal(24,8);
ALTER TABLE ticker MODIFY volume decimal(24,8);
ALTER TABLE summary_instances MODIFY balance decimal(24,8);
ALTER TABLE outstanding_premiums MODIFY balance decimal(24,8);
ALTER TABLE graph_data_ticker MODIFY buy decimal(24,8);
ALTER TABLE graph_data_ticker MODIFY sell decimal(24,8);
ALTER TABLE graph_data_ticker MODIFY volume decimal(24,8);
ALTER TABLE graph_data_ticker MODIFY last_trade_min decimal(24,8);
ALTER TABLE graph_data_ticker MODIFY last_trade_opening decimal(24,8);
ALTER TABLE graph_data_ticker MODIFY last_trade_closing decimal(24,8);
ALTER TABLE graph_data_ticker MODIFY last_trade_max decimal(24,8);
ALTER TABLE graph_data_summary MODIFY balance_min decimal(24,8);
ALTER TABLE graph_data_summary MODIFY balance_opening decimal(24,8);
ALTER TABLE graph_data_summary MODIFY balance_closing decimal(24,8);
ALTER TABLE graph_data_summary MODIFY balance_max decimal(24,8);
ALTER TABLE graph_data_balances MODIFY balance_min decimal(24,8);
ALTER TABLE graph_data_balances MODIFY balance_opening decimal(24,8);
ALTER TABLE graph_data_balances MODIFY balance_closing decimal(24,8);
ALTER TABLE graph_data_balances MODIFY balance_max decimal(24,8);
ALTER TABLE outstanding_premiums MODIFY paid_balance decimal(24,8) default 0;

DROP TABLE IF EXISTS dogecoin_blocks;

CREATE TABLE dogecoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

DROP TABLE IF EXISTS accounts_dogepoolpw;

CREATE TABLE accounts_dogepoolpw (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_elitistjerks;

CREATE TABLE accounts_elitistjerks (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_dogechainpool;

CREATE TABLE accounts_dogechainpool (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_hashfaster_ltc;

CREATE TABLE accounts_hashfaster_ltc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_hashfaster_ftc;

CREATE TABLE accounts_hashfaster_ftc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_triplemining;

CREATE TABLE accounts_triplemining (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_ozcoin_ltc;

CREATE TABLE accounts_ozcoin_ltc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_ozcoin_btc;

CREATE TABLE accounts_ozcoin_btc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_scryptpools;

CREATE TABLE accounts_scryptpools (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue datetime,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- we remove is_recent from ticker to hopefully increase performance
CREATE TABLE ticker_recent (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) not null,
  currency1 varchar(3) not null,
  currency2 varchar(3) not null,

  last_trade decimal(24,8) null,
  buy decimal(24,8) null,
  sell decimal(24,8) null,
  volume decimal(24,8) null,

  job_id int null,

  UNIQUE(exchange, currency1, currency2), INDEX(job_id)
);

ALTER TABLE ticker DROP is_recent;

ALTER TABLE ticker ADD INDEX(exchange, currency1, currency2);
ALTER TABLE ticker DROP INDEX exchange;
ALTER TABLE ticker DROP INDEX currency1;
ALTER TABLE ticker DROP INDEX currency2;

ALTER TABLE balances ADD INDEX(user_id, account_id, exchange);
ALTER TABLE hashrates ADD INDEX(user_id, account_id, exchange);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.15 to 0.16
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

-- make the account wizard pages much faster
ALTER TABLE jobs ADD INDEX(is_recent, user_id, job_type, arg_id);

-- we don't need to use the entire index at once, adding is_recent onto the end should make this faster
ALTER TABLE balances DROP INDEX user_id_2;  -- NOTE check that user_id_2 is a valid index name
ALTER TABLE balances ADD INDEX(user_id, account_id, exchange, is_recent);

ALTER TABLE hashrates DROP INDEX user_id_2; -- NOTE check that user_id_2 is a valid index name
ALTER TABLE hashrates ADD INDEX(user_id, account_id, exchange, is_recent);

-- removing 50btc
UPDATE accounts_50btc SET is_disabled=1;

-- newly created accounts should be last_queue with timestamp, not datetime, for consistency with other tables
ALTER TABLE accounts_scryptpools MODIFY last_queue timestamp null;
ALTER TABLE accounts_ozcoin_btc MODIFY last_queue timestamp null;
ALTER TABLE accounts_ozcoin_ltc MODIFY last_queue timestamp null;
ALTER TABLE accounts_triplemining MODIFY last_queue timestamp null;
ALTER TABLE accounts_hashfaster_ftc MODIFY last_queue timestamp null;
ALTER TABLE accounts_hashfaster_ltc MODIFY last_queue timestamp null;
ALTER TABLE accounts_dogechainpool MODIFY last_queue timestamp null;
ALTER TABLE accounts_elitistjerks MODIFY last_queue timestamp null;
ALTER TABLE accounts_dogepoolpw MODIFY last_queue timestamp null;
ALTER TABLE accounts_litecoinpool MODIFY last_queue timestamp null;
ALTER TABLE accounts_beeeeer MODIFY last_queue timestamp null;
ALTER TABLE accounts_lite_coinpool MODIFY last_queue timestamp null;
ALTER TABLE accounts_eligius MODIFY last_queue timestamp null;
ALTER TABLE accounts_coinhuntr MODIFY last_queue timestamp null;
ALTER TABLE accounts_litepooleu MODIFY last_queue timestamp null;

-- email notifications!
-- another architecture would be [notifications] table with references to [notification_type] and a notification_type table for storing parameters
--
-- option 1: execute notification checks after every balance/ticker/hashrate change.
-- - could be very database intensive, particularly for hourly notifications or lots of them
-- - but will not miss changes within a particular period
-- - easy to implement 'minute' period notifications
--
-- option 2: execute notifications just like other jobs.
-- - easy to control and manage and implement, can run notification jobs separately
-- - will miss changes within a particular period
-- - need to be executed AFTER an update job
-- - will be interrupted by premium jobs
-- - can store last_value when processing job
-- - queue timing will NOT be accurate (e.g. [period]*0.8+delay)
-- - fewer temporary errors, e.g. an API returns 0 briefly
--
-- suboption: run all 'notification' jobs hourly [or 12 hourly for free users], rather than using last_queue+period
-- - will allow 'daily', 'weekly' etc jobs to catch recent changes
-- - will not allow storage of last_value when processing job
-- - could run more frequently than hourly if necessary
-- - could be varied for premium users (e.g. every 10 minutes rather than hourly)
--
DROP TABLE IF EXISTS notifications;
CREATE TABLE notifications (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,

  last_queue timestamp null,
  last_value decimal(24,8) null,

  notification_type varchar(16) not null,     -- 'summary_instances', 'balances', 'hashrates', 'ticker', 'address_balances'
  type_id int not null,

  trigger_condition varchar(16) not null,     -- 'below', 'above', 'equal', 'not', 'increases', 'decreases', 'increases_by', 'decreases_by'
  trigger_value decimal(24,8) null,
  is_percent tinyint not null default 0,
  period varchar(8) not null,         -- 'hour', 'day', 'week', 'month'

  -- note that 'below' etc notifications will NOT be sent again unless this is false (so we don't continually receive notifications)
  -- or trigger_condition = increases_by, decreases_by, increases, decreases
  is_notified tinyint not null default 0,
  last_notification timestamp null,

  INDEX(user_id),
  INDEX(notification_type, type_id),
  INDEX(last_queue)
);

DROP TABLE IF EXISTS notifications_summary_instances;
CREATE TABLE notifications_summary_instances (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  summary_type varchar(32) not null
);

DROP TABLE IF EXISTS notifications_ticker;
CREATE TABLE notifications_ticker (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) not null,
  currency1 varchar(3) not null,
  currency2 varchar(3) not null
);

DROP TABLE IF EXISTS notifications_balances;
CREATE TABLE notifications_balances (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) null,  -- null = any exchange
  account_id int not null,    -- null = any account

  INDEX(exchange, account_id)
);

DROP TABLE IF EXISTS notifications_hashrates;
CREATE TABLE notifications_hashrates (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) null,  -- null = any exchange
  currency varchar(3) not null,
  account_id int, -- null = any account

  INDEX(exchange, currency, account_id)
);

DROP TABLE IF EXISTS notifications_address_balances;
CREATE TABLE notifications_address_balances (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  currency varchar(3) not null,
  address_id int not null,    -- don't support arbitrary 'any address' - will require a lot of querying!

  INDEX(currency, address_id)
);

-- delta graphs
-- empty, absolute, percent
ALTER TABLE graphs ADD delta VARCHAR(8) NOT NULL DEFAULT "";

DROP TABLE IF EXISTS accounts_bitcurex_pln;

CREATE TABLE accounts_bitcurex_pln (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

INSERT INTO exchanges SET name='bitcurex';

DROP TABLE IF EXISTS accounts_bitcurex_eur;

CREATE TABLE accounts_bitcurex_eur (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_hashfaster_doge;

CREATE TABLE accounts_hashfaster_doge (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_justcoin;

CREATE TABLE accounts_justcoin (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

INSERT INTO exchanges SET name='justcoin';

-- we insert these securities manually for now
INSERT INTO securities_cryptotrade SET name='AMC', currency='btc';  -- ACTIVEMININGCORP
INSERT INTO securities_cryptotrade SET name='GGB', currency='btc';  -- GALTS-GULCH-ORGANIC

-- give crypto-trade securities names
-- it sure would be nice if crypto-trade provided an API to list securities and their names, rather than inserting them in manually
ALTER TABLE securities_cryptotrade ADD title VARCHAR(64) NOT NULL;

UPDATE securities_cryptotrade SET title='CRYPTO-TRADE-BTC' WHERE name='CTB';
UPDATE securities_cryptotrade SET title='CRYPTO-TRADE-LTC' WHERE name='CTL';
UPDATE securities_cryptotrade SET title='ESECURITYSA-BTC' WHERE name='ESB';
UPDATE securities_cryptotrade SET title='ESECURITYSA-LTC' WHERE name='ESL';
UPDATE securities_cryptotrade SET title='ACTIVEMININGCORP' WHERE name='AMC';
UPDATE securities_cryptotrade SET title='GALTS-GULCH-ORGANIC' WHERE name='GGB';

DROP TABLE IF EXISTS accounts_multipool;

CREATE TABLE accounts_multipool (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_wemineftc;

CREATE TABLE accounts_wemineftc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

ALTER TABLE users ADD notifications_sent int not null default 0;
ALTER TABLE notifications ADD notifications_sent int not null default 0;

ALTER TABLE site_statistics ADD notifications_sent int;
ALTER TABLE site_statistics ADD max_notifications_sent int;

DROP TABLE IF EXISTS accounts_ypool;

CREATE TABLE accounts_ypool (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- multipool balances were all incorrect
DELETE FROM hashrates WHERE exchange='multipool';

-- --------------------------------------------------------------------------
-- upgrade statements from 0.16 to 0.16.2
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

ALTER TABLE accounts_generic ADD multiplier decimal(24,8) not null default 1;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.16.2 to 0.17
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- particularly critical for resolving #22
-- --------------------------------------------------------------------------

-- issue #22: some buy/sell values are the wrong way around
-- The 'bid' price is the highest price that a buyer is willing to pay (i.e. the 'sell');
-- the 'ask' price is the lowest price that a seller is willing to sell (i.e. the 'buy').
-- Therefore bid <= ask, sell <= buy.
ALTER TABLE ticker CHANGE buy ask decimal(24,8);
ALTER TABLE ticker CHANGE sell bid decimal(24,8);
ALTER TABLE graph_data_ticker CHANGE buy ask decimal(24,8);
ALTER TABLE graph_data_ticker CHANGE sell bid decimal(24,8);
ALTER TABLE ticker_recent CHANGE buy ask decimal(24,8);
ALTER TABLE ticker_recent CHANGE sell bid decimal(24,8);

update ticker_recent set ask=(@temp:=ask), ask=bid, bid=@temp;

update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='bitcurex';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='bitcurex';
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='bitnz';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='bitnz';
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='bitstamp';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='bitstamp';
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='btcchina';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='btcchina';
-- btce is fine
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='cexio';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='cexio';
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='coins-e';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='coins-e';
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='crypto-trade';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='crypto-trade';
-- cryptsy is fine
-- justcoin is half fine
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='justcoin' AND currency2='btc';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='justcoin' AND currency2='btc';
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='mtgox';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='mtgox';
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='vircurex';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='vircurex';
update ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='virtex';
update graph_data_ticker set ask=(@temp:=ask), ask=bid, bid=@temp where exchange='virtex';

DROP TABLE IF EXISTS namecoin_blocks;

CREATE TABLE namecoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

DROP TABLE IF EXISTS accounts_ghashio;

CREATE TABLE accounts_ghashio (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_username varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_coinbase;

CREATE TABLE accounts_coinbase (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),

  -- fields managed through OAuth2
  api_code varchar(255) not null,
  refresh_token varchar(255) null,
  access_token varchar(255) null,
  access_token_expires datetime null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

INSERT INTO exchanges SET name='coinbase';

-- removing bips
UPDATE accounts_bips SET is_disabled=1;

DROP TABLE IF EXISTS accounts_litecoininvest;

CREATE TABLE accounts_litecoininvest (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

CREATE TABLE securities_litecoininvest (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp null,

  name varchar(64) not null,

  INDEX(last_queue)
);

CREATE TABLE accounts_individual_litecoininvest (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  quantity int not null,
  security_id int not null,   -- to securities_litecoininvest

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(security_id), INDEX(is_disabled)
);

INSERT INTO securities_update SET exchange='litecoininvest';

DROP TABLE IF EXISTS accounts_btcinve;

CREATE TABLE accounts_btcinve (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

CREATE TABLE securities_btcinve (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp null,

  name varchar(64) not null,

  INDEX(last_queue)
);

CREATE TABLE accounts_individual_btcinve (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  quantity int not null,
  security_id int not null,   -- to securities_litecoininvest

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(security_id), INDEX(is_disabled)
);

INSERT INTO securities_update SET exchange='btcinve';

-- --------------------------------------------------------------------------
-- upgrade statements from 0.17 to 0.18
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

DROP TABLE IF EXISTS megacoin_blocks;

CREATE TABLE megacoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

DROP TABLE IF EXISTS accounts_miningpoolco;

CREATE TABLE accounts_miningpoolco (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_vaultofsatoshi;

CREATE TABLE accounts_vaultofsatoshi (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

INSERT INTO exchanges SET name='vaultofsatoshi';

-- issue #58: allow tracking of when summary currencies change
ALTER TABLE users ADD last_summaries_update datetime null;

-- removing lite_coinpool
UPDATE accounts_lite_coinpool SET is_disabled=1;

-- issue #49: while we are re-adding 50BTC we can't re-enable existing accounts
-- because the API key format has changed
UPDATE accounts_50btc SET is_disabled=1;

DROP TABLE IF EXISTS accounts_smalltimeminer_mec;

CREATE TABLE accounts_smalltimeminer_mec (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_ecoining_ppc;

CREATE TABLE accounts_ecoining_ppc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_teamdoge;

CREATE TABLE accounts_teamdoge (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_dedicatedpool_doge;

CREATE TABLE accounts_dedicatedpool_doge (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

DROP TABLE IF EXISTS accounts_nut2pools_ftc;

CREATE TABLE accounts_nut2pools_ftc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- 796 xchange; always changing their APIs silently with no BC

UPDATE securities_796 SET api_name='mri' where name='mri';

-- --------------------------------------------------------------------------
-- upgrade statements from 0.18 to 0.18.1
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------

DROP TABLE IF EXISTS cached_strings;

CREATE TABLE cached_strings (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  cache_key varchar(255) not null,
  cache_hash varchar(32) not null,

  content mediumblob not null, /* up to 16 MB */

  UNIQUE(cache_key, cache_hash)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.18.1 to 0.19
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

-- issue #98: removing smalltimeminer_mec
UPDATE accounts_smalltimeminer_mec SET is_disabled=1;

-- issue #93: removing litecoinglobal
DELETE FROM securities_update WHERE exchange='litecoinglobal';
UPDATE accounts_litecoinglobal SET is_disabled=1;
UPDATE accounts_individual_litecoinglobal SET is_disabled=1;

-- remove invalid data
DELETE FROM balances WHERE exchange='securities_litecoinglobal' AND balance=0 AND created_at >= '2013-09-24';
DELETE FROM graph_data_balances WHERE exchange='securities_litecoinglobal' AND balance_max=0 AND created_at >= '2013-09-24';

-- issue #93: removing btct
DELETE FROM securities_update WHERE exchange='btct';
UPDATE accounts_btct SET is_disabled=1;
UPDATE accounts_individual_btct SET is_disabled=1;

-- remove invalid data
DELETE FROM balances WHERE exchange='securities_btct' AND balance=0 AND created_at >= '2013-09-24';
DELETE FROM graph_data_balances WHERE exchange='securities_btct' AND balance_max=0 AND created_at >= '2013-09-24';

-- issue #104: Cryptsy support using application keys
CREATE TABLE accounts_cryptsy (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_public_key varchar(255) not null,
  api_private_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- issue #42: add shibepool.com DOGE mining pool
DROP TABLE IF EXISTS accounts_shibepool;

CREATE TABLE accounts_shibepool (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- issue #86: add Digitalcoin DGC cryptocurrency
DROP TABLE IF EXISTS digitalcoin_blocks;

CREATE TABLE digitalcoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #117: add DGC Cryptopools mining pool
DROP TABLE IF EXISTS accounts_cryptopools_dgc;

CREATE TABLE accounts_cryptopools_dgc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- issue #107: add Worldcoin WDC cryptocurrency
DROP TABLE IF EXISTS worldcoin_blocks;

CREATE TABLE worldcoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #118: add DGC Cryptopools mining pool
DROP TABLE IF EXISTS accounts_d2_wdc;

CREATE TABLE accounts_d2_wdc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.19 to 0.19.1
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

-- issue #135: track performance metrics
-- all times are in ms
DROP TABLE IF EXISTS performance_metrics_jobs;
CREATE TABLE performance_metrics_jobs (
  id int not null auto_increment primary key,
  time_taken int not null,

  job_type varchar(255) not null,
  arg0 varchar(255) null,     -- e.g. 'btce' for ticker
  job_failure tinyint not null default 0,
  runtime_exception varchar(255) null,

  -- timed_sql
  db_prepares int null,
  db_executes int null,
  db_fetches int null,
  db_fetch_alls int null,
  db_prepare_time int null,
  db_execute_time int null,
  db_fetch_time int null,
  db_fetch_all_time int null,

  -- timed_curl
  curl_requests int null,
  curl_request_time int null,

  INDEX(job_type)
);

DROP TABLE IF EXISTS performance_metrics_pages;
CREATE TABLE performance_metrics_pages (
  id int not null auto_increment primary key,
  time_taken int not null,

  script_name varchar(255) null,      -- might be null if running from CLI; probably not though
  is_logged_in tinyint not null,

  -- timed_sql
  db_prepares int null,
  db_executes int null,
  db_fetches int null,
  db_fetch_alls int null,
  db_prepare_time int null,
  db_execute_time int null,
  db_fetch_time int null,
  db_fetch_all_time int null,

  -- timed_curl
  curl_requests int null,
  curl_request_time int null,

  INDEX(script_name)
);

DROP TABLE IF EXISTS performance_metrics_graphs;
CREATE TABLE performance_metrics_graphs (
  id int not null auto_increment primary key,
  time_taken int not null,

  graph_type varchar(32) null,
  is_logged_in tinyint not null,
  days int null,          -- could be null, e.g. admin graphs
  has_technicals tinyint not null default 0,

  -- timed_sql
  db_prepares int null,
  db_executes int null,
  db_fetches int null,
  db_fetch_alls int null,
  db_prepare_time int null,
  db_execute_time int null,
  db_fetch_time int null,
  db_fetch_all_time int null,

  -- timed_curl
  curl_requests int null,
  curl_request_time int null,

  INDEX(graph_type)
);

DROP TABLE IF EXISTS performance_metrics_queues;
CREATE TABLE performance_metrics_queues (
  id int not null auto_increment primary key,
  time_taken int not null,

  user_id int null,
  priority int null,
  job_types varchar(255) null,
  premium_only tinyint null,

  -- timed_sql
  db_prepares int null,
  db_executes int null,
  db_fetches int null,
  db_fetch_alls int null,
  db_prepare_time int null,
  db_execute_time int null,
  db_fetch_time int null,
  db_fetch_all_time int null,

  -- timed_curl
  curl_requests int null,
  curl_request_time int null,

  INDEX(user_id), INDEX(premium_only)
);

DROP TABLE IF EXISTS performance_metrics_queries;
CREATE TABLE performance_metrics_queries (
  id int not null auto_increment primary key,
  query varchar(255) not null,
  created_at timestamp not null default current_timestamp,

  INDEX(query)
);

DROP TABLE IF EXISTS performance_metrics_slow_queries;
CREATE TABLE performance_metrics_slow_queries (
  id int not null auto_increment primary key,
  query_id int not null,      -- reference to performance_metrics_queries
  query_count int not null,
  query_time int not null,
  page_id int not null,       -- reference to performance_metrics_pages

  INDEX(query_id)
);

DROP TABLE IF EXISTS performance_metrics_repeated_queries;
CREATE TABLE performance_metrics_repeated_queries (
  id int not null auto_increment primary key,
  query_id int not null,      -- reference to performance_metrics_queries
  query_count int not null,
  query_time int not null,
  page_id int not null,       -- reference to performance_metrics_pages

  INDEX(query_id)
);

DROP TABLE IF EXISTS performance_metrics_urls;
CREATE TABLE performance_metrics_urls (
  id int not null auto_increment primary key,
  url varchar(255) not null,
  created_at timestamp not null default current_timestamp,

  INDEX(url)
);

DROP TABLE IF EXISTS performance_metrics_slow_urls;
CREATE TABLE performance_metrics_slow_urls (
  id int not null auto_increment primary key,
  url_id int not null,        -- reference to performance_metrics_urls
  url_count int not null,
  url_time int not null,
  page_id int not null,       -- reference to performance_metrics_pages

  INDEX(url_id)
);

DROP TABLE IF EXISTS performance_metrics_repeated_urls;
CREATE TABLE performance_metrics_repeated_urls (
  id int not null auto_increment primary key,
  url_id int not null,        -- reference to performance_metrics_urls
  url_count int not null,
  url_time int not null,
  page_id int not null,       -- reference to performance_metrics_pages

  INDEX(url_id)
);

-- and once data is collected, we compile them into reports that admins can look at
DROP TABLE IF EXISTS performance_reports;
CREATE TABLE performance_reports (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,
  report_type varchar(32) not null,

  INDEX(report_type)
);

DROP TABLE IF EXISTS performance_report_slow_queries;
CREATE TABLE performance_report_slow_queries (
  id int not null auto_increment primary key,
  report_id int not null,     -- reference to performance_reports

  query_id int not null,      -- reference to performance_metrics_queries
  query_count int not null,
  query_time int not null,
  page_id int not null,       -- reference to performance_metrics_pages

  INDEX(report_id)
);

DROP TABLE IF EXISTS performance_report_slow_urls;
CREATE TABLE performance_report_slow_urls (
  id int not null auto_increment primary key,
  report_id int not null,     -- reference to performance_reports

  url_id int not null,        -- reference to performance_metrics_urls
  url_count int not null,
  url_time int not null,
  page_id int not null,       -- reference to performance_metrics_pages

  INDEX(report_id)
);

DROP TABLE IF EXISTS performance_report_slow_jobs;
CREATE TABLE performance_report_slow_jobs (
  id int not null auto_increment primary key,
  report_id int not null,     -- reference to performance_reports

  job_type varchar(32) not null,
  job_count int not null,
  job_time int not null,

  INDEX(report_id)
);

DROP TABLE IF EXISTS performance_report_slow_pages;
CREATE TABLE performance_report_slow_pages (
  id int not null auto_increment primary key,
  report_id int not null,     -- reference to performance_reports

  script_name varchar(32) not null,
  page_count int not null,
  page_time int not null,

  INDEX(report_id)
);

DROP TABLE IF EXISTS performance_report_slow_graphs;
CREATE TABLE performance_report_slow_graphs (
  id int not null auto_increment primary key,
  report_id int not null,     -- reference to performance_reports

  graph_type varchar(32) not null,
  graph_count int not null,
  graph_time int not null,

  INDEX(report_id)
);

ALTER TABLE performance_metrics_jobs ADD created_at timestamp not null default current_timestamp;

DROP TABLE IF EXISTS performance_report_job_frequency;
CREATE TABLE performance_report_job_frequency (
  id int not null auto_increment primary key,
  report_id int not null,     -- reference to performance_reports

  job_type varchar(32) not null,
  job_count int not null,
  jobs_per_hour int not null,

  INDEX(report_id)
);

ALTER TABLE performance_report_slow_jobs ADD job_database int null;
ALTER TABLE performance_report_slow_pages ADD page_database int null;
ALTER TABLE performance_report_slow_graphs ADD graph_database int null;

ALTER TABLE site_statistics ADD mysql_locks_immediate int;
ALTER TABLE site_statistics ADD mysql_locks_blocked int;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.19.1 to 0.20
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

-- issue #133: improve performance of admin page
ALTER TABLE jobs ADD INDEX(created_at);
ALTER TABLE uncaught_exceptions ADD INDEX(created_at);
ALTER TABLE ticker ADD INDEX(created_at);

-- issue #121: track supported currencies from API responses
-- we don't track pairs (I think that's too much work), just the currencies supported
DROP TABLE IF EXISTS reported_currencies;
CREATE TABLE reported_currencies (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) not null,
  currency varchar(16) not null,  -- we could be getting currencies in any format or length

  INDEX(exchange, currency)
);

ALTER TABLE exchanges ADD track_reported_currencies tinyint not null default 0;
ALTER TABLE exchanges ADD INDEX(track_reported_currencies);

UPDATE exchanges SET track_reported_currencies=1 WHERE name='vaultofsatoshi';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='btce';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='cexio';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='coinbase';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='coins-e';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='crypto-trade';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='cryptsy';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='justcoin';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='themoneyconverter';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='vircurex';

-- issue #89: add support for bit2c exchange
DROP TABLE IF EXISTS accounts_bit2c;

CREATE TABLE accounts_bit2c (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

INSERT INTO exchanges SET name='bit2c';

-- issue #109: add Ixcoin IXC cryptocurrency
DROP TABLE IF EXISTS ixcoin_blocks;

CREATE TABLE ixcoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #108: add Netcoin NET cryptocurrency
DROP TABLE IF EXISTS netcoin_blocks;

CREATE TABLE netcoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #44: add Hobonickels HBN cryptocurrency
DROP TABLE IF EXISTS hobonickels_blocks;

CREATE TABLE hobonickels_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #90: add scryptguild mining pool
DROP TABLE IF EXISTS accounts_scryptguild;

CREATE TABLE accounts_scryptguild (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.20 to 0.21
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

-- implement i18n
ALTER TABLE users ADD locale VARCHAR(6) NULL;
ALTER TABLE users ADD INDEX(locale);

-- allow securities_cryptostocks accounts to be disabled automatically
ALTER TABLE securities_cryptostocks ADD is_disabled tinyint not null default 0;
ALTER TABLE securities_cryptostocks ADD failures tinyint not null default 0;
ALTER TABLE securities_cryptostocks ADD first_failure timestamp null;
ALTER TABLE securities_cryptostocks ADD INDEX(is_disabled);

-- allow securities_cryptotrade accounts to be disabled automatically
ALTER TABLE securities_cryptotrade ADD is_disabled tinyint not null default 0;
ALTER TABLE securities_cryptotrade ADD failures tinyint not null default 0;
ALTER TABLE securities_cryptotrade ADD first_failure timestamp null;
ALTER TABLE securities_cryptotrade ADD INDEX(is_disabled);

-- issue #178: missing virtex LTC rates
DELETE FROM ticker_recent WHERE exchange='virtex';

UPDATE ticker SET currency1='cad', currency2='btc' WHERE exchange='virtex' AND currency1='btc' AND currency2='cad';
UPDATE ticker_recent SET currency1='cad', currency2='btc' WHERE exchange='virtex' AND currency1='btc' AND currency2='cad';

UPDATE ticker SET currency1='btc', currency2='ltc' WHERE exchange='virtex' AND currency1='ltc' AND currency2='btc';
UPDATE ticker_recent SET currency1='btc', currency2='ltc' WHERE exchange='virtex' AND currency1='ltc' AND currency2='btc';

UPDATE ticker SET currency1='cad', currency2='ltc' WHERE exchange='virtex' AND currency1='ltc' AND currency2='cad';
UPDATE ticker_recent SET currency1='cad', currency2='ltc' WHERE exchange='virtex' AND currency1='ltc' AND currency2='cad';

-- issue #142: support username/password login
ALTER TABLE users ADD password_hash VARCHAR(64) NULL;
ALTER TABLE users ADD INDEX(password_hash);

ALTER TABLE users ADD password_last_changed datetime null;

ALTER TABLE users ADD last_password_reset datetime null;

-- issue #177: add created_at_day index to balance, ticker tables
ALTER TABLE balances ADD created_at_day mediumint not null;
UPDATE balances SET created_at_day=TO_DAYS(created_at);
ALTER TABLE balances ADD INDEX(created_at_day);

ALTER TABLE hashrates ADD created_at_day mediumint not null;
UPDATE hashrates SET created_at_day=TO_DAYS(created_at);
ALTER TABLE hashrates ADD INDEX(created_at_day);

ALTER TABLE summary_instances ADD created_at_day mediumint not null;
UPDATE summary_instances SET created_at_day=TO_DAYS(created_at);
ALTER TABLE summary_instances ADD INDEX(created_at_day);

ALTER TABLE ticker ADD created_at_day mediumint not null;
UPDATE ticker SET created_at_day=TO_DAYS(created_at);
ALTER TABLE ticker ADD INDEX(created_at_day);

ALTER TABLE graph_data_balances ADD data_date_day mediumint not null;
UPDATE graph_data_balances SET data_date_day=TO_DAYS(data_date);
ALTER TABLE graph_data_balances ADD INDEX(data_date_day);

-- issue #194: track account transactions
-- we will get the system to populate these automatically (which could be user-configurable)
-- and allow users to add/remove entries as well
DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions (
  id int not null auto_increment primary key,
  user_id int not null,

  created_at timestamp not null default current_timestamp,
  updated_at timestamp null,
  is_automatic tinyint not null default 0,

  transaction_date timestamp not null,
  transaction_date_day mediumint not null,
  exchange varchar(32) not null,
  account_id int not null,

  -- optional fields for user entered transactions
  description varchar(255) null,
  -- category_id int null,
  reference varchar(255) null,

  currency1 varchar(3) null,
  value1 decimal(24,8) null,
  currency2 varchar(3) null,
  value2 decimal(24,8) null,

  INDEX(user_id, exchange, account_id, transaction_date),
  INDEX(exchange), INDEX(currency1), INDEX(currency2), INDEX(transaction_date_day)
);

-- for doing multiple batch jobs, tracking automatic daily transaction creation
DROP TABLE IF EXISTS transaction_creators;

CREATE TABLE transaction_creators (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  exchange varchar(32) not null,
  account_id int not null,

  transaction_cursor mediumint not null default 0,

  -- is_disabled can also be used by a user to specifically disable a creator
  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(is_disabled)
);

ALTER TABLE users ADD last_tx_creator_queue timestamp null;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.21 to 0.22
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

-- issue #204: convert database to UTF-8 rather than latin1 (or any other encoding)
-- first, new database tables
ALTER DATABASE clerk CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- then, existing database tables
ALTER TABLE accounts_50btc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_796 CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_beeeeer CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_bips CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_bit2c CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_bitcurex_eur CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_bitcurex_pln CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_bitfunder CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_bitminter CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_bitstamp CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_btce CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_btcguild CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_btcinve CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_btct CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_cexio CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_coinbase CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_coinhuntr CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_cryptopools_dgc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_cryptostocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_cryptotrade CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_cryptsy CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_d2_wdc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_dedicatedpool_doge CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_dogechainpool CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_dogepoolpw CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_ecoining_ppc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_eligius CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_elitistjerks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_generic CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_ghashio CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_givemecoins CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_hashfaster_doge CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_hashfaster_ftc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_hashfaster_ltc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_havelock CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_hypernova CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_individual_796 CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_individual_bitfunder CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_individual_btcinve CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_individual_btct CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_individual_cryptostocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_individual_cryptotrade CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_individual_havelock CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_individual_litecoinglobal CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_individual_litecoininvest CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_justcoin CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_kattare CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_khore CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_lite_coinpool CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_litecoinglobal CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_litecoininvest CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_litecoinpool CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_liteguardian CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_litepooleu CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_ltcmineru CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_miningforeman CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_miningforeman_ftc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_miningpoolco CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_mtgox CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_multipool CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_nut2pools_ftc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_ozcoin_btc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_ozcoin_ltc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_poolx CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_scryptguild CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_scryptpools CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_shibepool CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_slush CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_smalltimeminer_mec CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_teamdoge CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_triplemining CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_vaultofsatoshi CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_vircurex CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_wemineftc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_wemineltc CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE accounts_ypool CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE address_balances CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE addresses CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE admin_messages CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE balances CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE cached_strings CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE digitalcoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE dogecoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE exchanges CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE external_status CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE external_status_types CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE feathercoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE graph_data_balances CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE graph_data_summary CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE graph_data_ticker CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE graph_pages CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE graph_technicals CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE graphs CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE hashrates CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE heavy_requests CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE hobonickels_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE ixcoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE jobs CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE litecoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE managed_graphs CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE megacoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE namecoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE netcoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE notifications CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE notifications_address_balances CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE notifications_balances CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE notifications_hashrates CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE notifications_summary_instances CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE notifications_ticker CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE novacoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE offsets CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE openid_identities CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE outstanding_premiums CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE pending_subscriptions CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_graphs CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_jobs CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_pages CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_queries CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_queues CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_repeated_queries CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_repeated_urls CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_slow_queries CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_slow_urls CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_metrics_urls CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_report_job_frequency CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_report_slow_graphs CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_report_slow_jobs CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_report_slow_pages CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_report_slow_queries CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_report_slow_urls CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE performance_reports CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE ppcoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE premium_addresses CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE primecoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE reported_currencies CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_796 CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_bitfunder CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_btcinve CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_btct CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_cryptostocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_cryptotrade CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_havelock CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_litecoinglobal CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_litecoininvest CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE securities_update CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE site_statistics CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE summaries CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE summary_instances CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE terracoin_blocks CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE ticker CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE ticker_recent CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE transaction_creators CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE transactions CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE uncaught_exceptions CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE users CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE valid_user_keys CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;
ALTER TABLE worldcoin_blocks  CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;

-- to see a table's character set: SHOW FULL COLUMNS FROM table_name;

-- issue #105: add Kraken exchange
DROP TABLE IF EXISTS accounts_kraken;

CREATE TABLE accounts_kraken (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled)
);
ALTER TABLE accounts_kraken CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;

INSERT INTO exchanges SET name='kraken';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='kraken';

-- issue #201: deleting an account does not delete old hashrate data
DELETE FROM hashrates WHERE exchange='50btc' AND account_id NOT IN (SELECT id FROM accounts_50btc);
DELETE FROM hashrates WHERE exchange='bitminter' AND account_id NOT IN (SELECT id FROM accounts_bitminter);
DELETE FROM hashrates WHERE exchange='btcguild' AND account_id NOT IN (SELECT id FROM accounts_btcguild);
DELETE FROM hashrates WHERE exchange='coinhuntr' AND account_id NOT IN (SELECT id FROM accounts_coinhuntr);
DELETE FROM hashrates WHERE exchange='dogechainpool' AND account_id NOT IN (SELECT id FROM accounts_dogechainpool);
DELETE FROM hashrates WHERE exchange='dogepoolpw' AND account_id NOT IN (SELECT id FROM accounts_dogepoolpw);
DELETE FROM hashrates WHERE exchange='ecoining_ppc' AND account_id NOT IN (SELECT id FROM accounts_ecoining_ppc);
DELETE FROM hashrates WHERE exchange='eligius' AND account_id NOT IN (SELECT id FROM accounts_eligius);
DELETE FROM hashrates WHERE exchange='ghashio' AND account_id NOT IN (SELECT id FROM accounts_ghashio);
DELETE FROM hashrates WHERE exchange='givemecoins' AND account_id NOT IN (SELECT id FROM accounts_givemecoins);
DELETE FROM hashrates WHERE exchange='hashfaster_doge' AND account_id NOT IN (SELECT id FROM accounts_hashfaster_doge);
DELETE FROM hashrates WHERE exchange='hashfaster_ftc' AND account_id NOT IN (SELECT id FROM accounts_hashfaster_ftc);
DELETE FROM hashrates WHERE exchange='hashfaster_ltc' AND account_id NOT IN (SELECT id FROM accounts_hashfaster_ltc);
DELETE FROM hashrates WHERE exchange='hypernova' AND account_id NOT IN (SELECT id FROM accounts_hypernova);
DELETE FROM hashrates WHERE exchange='kattare' AND account_id NOT IN (SELECT id FROM accounts_kattare);
DELETE FROM hashrates WHERE exchange='khore' AND account_id NOT IN (SELECT id FROM accounts_khore);
DELETE FROM hashrates WHERE exchange='litecoinpool' AND account_id NOT IN (SELECT id FROM accounts_litecoinpool);
DELETE FROM hashrates WHERE exchange='liteguardian' AND account_id NOT IN (SELECT id FROM accounts_liteguardian);
DELETE FROM hashrates WHERE exchange='lite_coinpool' AND account_id NOT IN (SELECT id FROM accounts_lite_coinpool);
DELETE FROM hashrates WHERE exchange='miningforeman' AND account_id NOT IN (SELECT id FROM accounts_miningforeman);
DELETE FROM hashrates WHERE exchange='miningpoolco' AND account_id NOT IN (SELECT id FROM accounts_miningpoolco);
DELETE FROM hashrates WHERE exchange='multipool' AND account_id NOT IN (SELECT id FROM accounts_multipool);
DELETE FROM hashrates WHERE exchange='nut2pools_ftc' AND account_id NOT IN (SELECT id FROM accounts_nut2pools_ftc);
DELETE FROM hashrates WHERE exchange='ozcoin_btc' AND account_id NOT IN (SELECT id FROM accounts_ozcoin_btc);
DELETE FROM hashrates WHERE exchange='ozcoin_ltc' AND account_id NOT IN (SELECT id FROM accounts_ozcoin_ltc);
DELETE FROM hashrates WHERE exchange='poolx' AND account_id NOT IN (SELECT id FROM accounts_poolx);
DELETE FROM hashrates WHERE exchange='scryptguild' AND account_id NOT IN (SELECT id FROM accounts_scryptguild);
DELETE FROM hashrates WHERE exchange='scryptpools' AND account_id NOT IN (SELECT id FROM accounts_scryptpools);
DELETE FROM hashrates WHERE exchange='slush' AND account_id NOT IN (SELECT id FROM accounts_slush);
DELETE FROM hashrates WHERE exchange='smalltimeminer_mec' AND account_id NOT IN (SELECT id FROM accounts_smalltimeminer_mec);
DELETE FROM hashrates WHERE exchange='teamdoge' AND account_id NOT IN (SELECT id FROM accounts_teamdoge);
DELETE FROM hashrates WHERE exchange='triplemining' AND account_id NOT IN (SELECT id FROM accounts_triplemining);
DELETE FROM hashrates WHERE exchange='wemineltc' AND account_id NOT IN (SELECT id FROM accounts_wemineltc);

-- issue #203: allow users to disable accounts

-- Addresses
-- Mining pools
ALTER TABLE accounts_50btc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_50btc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_beeeeer ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_beeeeer ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_bitminter ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_bitminter ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_btcguild ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_btcguild ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_coinhuntr ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_coinhuntr ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_cryptopools_dgc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_cryptopools_dgc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_d2_wdc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_d2_wdc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_dedicatedpool_doge ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_dedicatedpool_doge ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_dogechainpool ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_dogechainpool ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_dogepoolpw ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_dogepoolpw ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_ecoining_ppc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_ecoining_ppc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_eligius ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_eligius ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_elitistjerks ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_elitistjerks ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_ghashio ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_ghashio ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_givemecoins ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_givemecoins ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_hashfaster_doge ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_hashfaster_doge ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_hashfaster_ftc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_hashfaster_ftc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_hashfaster_ltc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_hashfaster_ltc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_hypernova ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_hypernova ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_kattare ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_kattare ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_khore ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_khore ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_lite_coinpool ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_lite_coinpool ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_litecoinpool ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_litecoinpool ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_liteguardian ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_liteguardian ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_litepooleu ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_litepooleu ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_ltcmineru ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_ltcmineru ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_miningforeman ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_miningforeman ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_miningforeman_ftc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_miningforeman_ftc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_miningpoolco ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_miningpoolco ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_multipool ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_multipool ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_nut2pools_ftc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_nut2pools_ftc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_ozcoin_btc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_ozcoin_btc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_ozcoin_ltc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_ozcoin_ltc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_poolx ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_poolx ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_scryptguild ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_scryptguild ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_scryptpools ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_scryptpools ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_shibepool ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_shibepool ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_slush ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_slush ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_smalltimeminer_mec ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_smalltimeminer_mec ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_teamdoge ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_teamdoge ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_triplemining ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_triplemining ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_wemineftc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_wemineftc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_wemineltc ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_wemineltc ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_ypool ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_ypool ADD INDEX(is_disabled_manually);
-- Exchanges
ALTER TABLE accounts_bips ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_bips ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_bit2c ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_bit2c ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_bitcurex_eur ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_bitcurex_eur ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_bitcurex_pln ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_bitcurex_pln ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_bitstamp ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_bitstamp ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_btce ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_btce ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_cexio ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_cexio ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_coinbase ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_coinbase ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_cryptotrade ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_cryptotrade ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_cryptsy ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_cryptsy ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_justcoin ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_justcoin ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_kraken ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_kraken ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_mtgox ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_mtgox ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_vaultofsatoshi ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_vaultofsatoshi ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_vircurex ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_vircurex ADD INDEX(is_disabled_manually);
-- Securities
ALTER TABLE accounts_796 ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_796 ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_bitfunder ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_bitfunder ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_btcinve ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_btcinve ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_btct ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_btct ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_cryptostocks ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_cryptostocks ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_havelock ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_havelock ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_litecoininvest ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_litecoininvest ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_litecoinglobal ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_litecoinglobal ADD INDEX(is_disabled_manually);
-- Individual Securities
ALTER TABLE accounts_individual_796 ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_individual_796 ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_individual_bitfunder ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_individual_bitfunder ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_individual_btcinve ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_individual_btcinve ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_individual_btct ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_individual_btct ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_individual_cryptotrade ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_individual_cryptotrade ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_individual_cryptostocks ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_individual_cryptostocks ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_individual_havelock ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_individual_havelock ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_individual_litecoininvest ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_individual_litecoininvest ADD INDEX(is_disabled_manually);
ALTER TABLE accounts_individual_litecoinglobal ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_individual_litecoinglobal ADD INDEX(is_disabled_manually);
-- Other
ALTER TABLE accounts_generic ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE accounts_generic ADD INDEX(is_disabled_manually);

-- issue #200: display out-of-date warning for new users
ALTER TABLE users ADD last_account_change timestamp null;

ALTER TABLE users ADD last_sum_job timestamp null;
ALTER TABLE users ADD has_added_account tinyint not null default 0;
ALTER TABLE users ADD INDEX(has_added_account);

-- Addresses
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM addresses);
-- Mining pools
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_50btc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_beeeeer);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_bitminter);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_btcguild);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_coinhuntr);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_cryptopools_dgc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_d2_wdc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_dedicatedpool_doge);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_dogechainpool);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_dogepoolpw);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_ecoining_ppc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_eligius);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_elitistjerks);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_ghashio);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_givemecoins);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_hashfaster_doge);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_hashfaster_ftc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_hashfaster_ltc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_hypernova);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_kattare);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_khore);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_lite_coinpool);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_litecoinpool);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_liteguardian);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_litepooleu);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_ltcmineru);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_miningforeman);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_miningforeman_ftc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_miningpoolco);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_multipool);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_nut2pools_ftc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_ozcoin_btc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_ozcoin_ltc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_poolx);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_scryptguild);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_scryptpools);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_shibepool);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_slush);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_smalltimeminer_mec);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_teamdoge);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_triplemining);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_wemineftc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_wemineltc);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_ypool);
-- Exchanges
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_bips);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_bit2c);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_bitcurex_eur);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_bitcurex_pln);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_bitstamp);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_btce);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_cexio);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_coinbase);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_cryptotrade);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_cryptsy);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_justcoin);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_kraken);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_mtgox);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_vaultofsatoshi);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_vircurex);
-- Securities
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_796);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_bitfunder);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_btcinve);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_btct);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_cryptotrade);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_cryptostocks);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_havelock);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_litecoininvest);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_litecoinglobal);
-- Individual Securities
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_individual_796);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_individual_bitfunder);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_individual_btcinve);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_individual_btct);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_individual_cryptotrade);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_individual_cryptostocks);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_individual_havelock);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_individual_litecoininvest);
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_individual_litecoinglobal);
-- Other
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM accounts_generic);

-- Also, offsets
UPDATE users SET has_added_account=1 WHERE id IN (SELECT user_id AS id FROM offsets);

-- issue #186: add cryptocurrency average price indices
INSERT INTO exchanges SET name='average';

-- this is only the most recent market count, we don't persist this long-term
DROP TABLE IF EXISTS average_market_count;

CREATE TABLE average_market_count (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  currency1 varchar(3) not null,
  currency2 varchar(3) not null,

  market_count int not null,

  UNIQUE(currency1, currency2)
);

-- we also want to generate lots of historical data for the average market
-- this query will be very heavy
DELETE FROM graph_data_ticker WHERE exchange='average';

INSERT INTO graph_data_ticker (
  SELECT NULL as id,
    NOW() as created_at,
    'average' AS exchange,
    currency1,
    currency2,
    MAX(data_date) AS data_date,
    COUNT(*) AS samples,
    SUM(ask * volume) / SUM(volume) AS ask,
    SUM(bid * volume) / SUM(volume) AS bid,
    SUM(volume) AS volume,
    SUM(last_trade_min * volume) / SUM(volume) AS last_trade_min,
    SUM(last_trade_opening * volume) / SUM(volume) AS last_trade_opening,
    SUM(last_trade_closing * volume) / SUM(volume) AS last_trade_closing,
    SUM(last_trade_max * volume) / SUM(volume) AS last_trade_max,
    0 AS last_trade_stdev
    FROM graph_data_ticker
      WHERE volume > 0
      GROUP BY currency1, currency2, data_date
);

-- also do data from 'ticker' that isn't yet in graph_data_ticker
INSERT INTO graph_data_ticker (
  SELECT NULL as id,
    NOW() as created_at,
    'average' AS exchange,
    currency1,
    currency2,
    MAX(created_at) AS data_date,
    COUNT(*) AS samples,
    SUM(ask * volume) / SUM(volume) AS ask,
    SUM(bid * volume) / SUM(volume) AS bid,
    SUM(volume) AS volume,
    0 AS last_trade_min,
    SUM(last_trade * volume) / SUM(volume) AS last_trade_opening,
    SUM(last_trade * volume) / SUM(volume) AS last_trade_closing,
    0 AS last_trade_max,
    0 AS last_trade_stdev
    FROM ticker
      WHERE volume > 0
      GROUP BY currency1, currency2, to_days(created_at)
);

-- issue #198: add rapidhash mining pool
DROP TABLE IF EXISTS accounts_rapidhash_doge;

CREATE TABLE accounts_rapidhash_doge (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

DROP TABLE IF EXISTS accounts_rapidhash_vtc;

CREATE TABLE accounts_rapidhash_vtc (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

-- issue #84: add cryptotroll doge mining pool
DROP TABLE IF EXISTS accounts_cryptotroll_doge;

CREATE TABLE accounts_cryptotroll_doge (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

-- issue #194: more database work for transactions
ALTER TABLE transaction_creators ADD is_disabled_manually tinyint not null default 0;
ALTER TABLE transaction_creators ADD INDEX(is_disabled_manually);

-- add is_daily_data, etc fields to address_balances
ALTER TABLE address_balances ADD is_daily_data tinyint not null default 0;
ALTER TABLE address_balances ADD INDEX(is_daily_data);

ALTER TABLE address_balances ADD created_at_day mediumint not null;
UPDATE address_balances SET created_at_day=TO_DAYS(created_at);
ALTER TABLE address_balances ADD INDEX(created_at_day);

-- select the last address_balance of each day to be daily data
CREATE TABLE temp (id int not null);
INSERT INTO temp (id)
  SELECT MAX(id) AS id FROM address_balances
  GROUP BY created_at_day, user_id, address_id;
-- using INNER JOIN is MUCH faster than WHERE (id) IN (SELECT)
UPDATE address_balances INNER JOIN temp ON address_balances.id=temp.id SET is_daily_data=1;
DROP TABLE temp;

ALTER TABLE transaction_creators ADD is_address tinyint not null default 0;
ALTER TABLE transaction_creators ADD INDEX(is_address);

-- stop NULLs getting in; if we have a transaction, it must have a currency and value (which may be 0) defined
ALTER TABLE transactions MODIFY currency1 varchar(3) not null;
ALTER TABLE transactions MODIFY value1 decimal(24,8) not null;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.22 to 0.23
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

DROP TABLE IF EXISTS finance_accounts;

CREATE TABLE finance_accounts (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,

  title varchar(255) not null,

  description varchar(255) null,
  gst varchar(64) null,

  INDEX(user_id)
);

DROP TABLE IF EXISTS finance_categories;

CREATE TABLE finance_categories (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,

  title varchar(255),
  description varchar(255) null,

  INDEX(user_id)
);

ALTER TABLE transactions ADD category_id int null;

ALTER TABLE graph_data_ticker ADD data_date_day mediumint not null;
UPDATE graph_data_ticker SET data_date_day=TO_DAYS(data_date);
ALTER TABLE graph_data_ticker ADD INDEX(data_date_day);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.23 to 0.25
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

-- issue #202: add BitMarket.pl exchange
DROP TABLE IF EXISTS accounts_bitmarket_pl;

CREATE TABLE accounts_bitmarket_pl (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

INSERT INTO exchanges SET name='bitmarket_pl';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='bitmarket_pl';

-- issue #213: add Poloniex exchange
DROP TABLE IF EXISTS accounts_poloniex;

CREATE TABLE accounts_poloniex (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,
  accept tinyint not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

INSERT INTO exchanges SET name='poloniex';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='poloniex';

-- issue #214: add MintPal exchange
INSERT INTO exchanges SET name='mintpal';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='mintpal';

-- issue #219: add MuPool.com mining pool
DROP TABLE IF EXISTS accounts_mupool;

CREATE TABLE accounts_mupool (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

-- issue #235: add ANXPRO exchange
DROP TABLE IF EXISTS accounts_anxpro;

CREATE TABLE accounts_anxpro (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

INSERT INTO exchanges SET name='anxpro';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='anxpro';

-- issue #231: send emails on partial premium payment
ALTER TABLE outstanding_premiums ADD last_balance DECIMAL(24, 8) null;
UPDATE outstanding_premiums SET last_balance=paid_balance;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.25 to 0.26
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

ALTER TABLE users ADD is_deleted tinyint not null default 0;
ALTER TABLE users ADD requested_delete_at timestamp null;

-- issue #199: add itBit exchange
INSERT INTO exchanges SET name='itbit';

-- issue #126: keep track of number of emails sent
ALTER TABLE users ADD emails_sent int not null default 0;
ALTER TABLE site_statistics ADD total_emails_sent int;

-- --------------------------------------------------------------------------
-- upgrade statements from 0.26 to 0.27
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

-- disable Mining Foreman accounts
UPDATE accounts_miningforeman SET is_disabled=1;
UPDATE accounts_miningforeman_ftc SET is_disabled=1;

-- issue #171: add Bittrex exchange
DROP TABLE IF EXISTS accounts_bittrex;

CREATE TABLE accounts_bittrex (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

INSERT INTO exchanges SET name='bittrex';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='bittrex';

-- issue #264: allow users to vote for new coins
DROP TABLE IF EXISTS vote_coins;
CREATE TABLE vote_coins (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  last_updated timestamp,
  total_votes float,
  total_users int,

  code varchar(32),
  title varchar(255)
);

DROP TABLE IF EXISTS vote_coins_votes;
CREATE TABLE vote_coins_votes (
  id int not null auto_increment primary key,
  user_id int not null,
  coin_id int not null,
  created_at timestamp not null default current_timestamp,

  INDEX(user_id), INDEX(coin_id)
);

-- issue #158: add Blackcoin BC cryptocurrency
DROP TABLE IF EXISTS blackcoin_blocks;

CREATE TABLE blackcoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.27 to 0.28
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

-- issue #274: add more simple pair tables
UPDATE graphs SET graph_type='pair_mtgox_usdbtc' WHERE graph_type='mtgox_btc_table';

-- ... continue from here

-- issue #285: use Vertcoin Explorer
DROP TABLE IF EXISTS vertcoin_blocks;

CREATE TABLE vertcoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #290: removing dogechainpool accounts
UPDATE accounts_dogechainpool SET is_disabled=1;

-- issue #300: removing hypernova.pw accounts
UPDATE accounts_hypernova SET is_disabled=1;

-- issue #291: allow securities tables to be enabled/disabled through admin_accounts interface
ALTER TABLE securities_796 ADD user_id int not null;
UPDATE securities_796 SET user_id=100;
ALTER TABLE securities_bitfunder ADD user_id int not null;
UPDATE securities_bitfunder SET user_id=100;
ALTER TABLE securities_btcinve ADD user_id int not null;
UPDATE securities_btcinve SET user_id=100;
ALTER TABLE securities_btct ADD user_id int not null;
UPDATE securities_btct SET user_id=100;
ALTER TABLE securities_cryptotrade ADD user_id int not null;
UPDATE securities_cryptotrade SET user_id=100;
ALTER TABLE securities_cryptostocks ADD user_id int not null;
UPDATE securities_cryptostocks SET user_id=100;
ALTER TABLE securities_havelock ADD user_id int not null;
UPDATE securities_havelock SET user_id=100;
ALTER TABLE securities_litecoininvest ADD user_id int not null;
UPDATE securities_litecoininvest SET user_id=100;
ALTER TABLE securities_litecoinglobal ADD user_id int not null;
UPDATE securities_litecoinglobal SET user_id=100;

ALTER TABLE securities_havelock ADD is_disabled_manually tinyint not null default 0;

-- re-enable all securities_havelock
UPDATE securities_havelock SET is_disabled=0;

-- issue #304: disable all automatic transaction generators
DELETE FROM transaction_creators;

-- and remove all automatic transactions
DELETE FROM transactions WHERE is_automatic=1;

-- issue #295: add Darkcoin DRK cryptocurrency
DROP TABLE IF EXISTS darkcoin_blocks;

CREATE TABLE darkcoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #307: add Darkcoin DRK cryptocurrency
DROP TABLE IF EXISTS vericoin_blocks;

CREATE TABLE vericoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #297: removing Bitcurex accounts
UPDATE accounts_bitcurex_eur SET is_disabled=1;
UPDATE accounts_bitcurex_pln SET is_disabled=1;

-- issue #303: remove dogepool.pw accounts
UPDATE accounts_dogepoolpw SET is_disabled=1;

-- issue #149: allow multiple labelled offsets per coin
-- we rewrite the 'offsets' table to add the columns necessary for our wizards
ALTER TABLE offsets ADD title varchar(255) null;
DELETE FROM offsets WHERE is_recent=0;
DELETE FROM offsets WHERE balance=0;
ALTER TABLE offsets DROP is_recent;

-- issue #314: remove Shibe Pool accounts
UPDATE accounts_shibepool SET is_disabled=1;

-- issue #262: allow notifications to be disabled
ALTER TABLE notifications ADD is_disabled tinyint not null default 0;
ALTER TABLE notifications ADD failures tinyint not null default 0;
ALTER TABLE notifications ADD first_failure timestamp null;
ALTER TABLE notifications ADD INDEX(is_disabled);

-- issue #243: store all historical ticker data before trimming
CREATE TABLE ticker_historical (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  exchange varchar(32) not null,
  currency1 varchar(3),
  currency2 varchar(3),
  last_trade decimal(24, 8),
  ask decimal(24, 8),
  bid decimal(24, 8),
  volume decimal(24, 8),
  is_daily_data tinyint not null default 0,
  job_id int,
  created_at_day mediumint not null,

  INDEX(currency1), INDEX(currency2), INDEX(is_daily_data),
  INDEX(exchange, currency1, currency2), INDEX(created_at), INDEX(created_at_day)
);

-- initialise with everything
REPLACE INTO ticker_historical (SELECT * FROM ticker);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.28 to 0.29
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

ALTER TABLE exchanges ADD is_disabled tinyint not null default 0;
ALTER TABLE exchanges ADD INDEX(is_disabled);
UPDATE exchanges SET is_disabled=1 WHERE name='mintpal';

-- issue #316: remove Mt.Gox exchange ticker
UPDATE exchanges SET is_disabled=1 WHERE name='mtgox';

-- issue #303: remove b(e^5)r.org accounts
UPDATE accounts_beeeeer SET is_disabled=1;

-- issue #316: remove Mt.Gox accounts
UPDATE accounts_mtgox SET is_disabled=1;

-- issue #317: remove Scryptguild accounts
UPDATE accounts_scryptguild SET is_disabled=1;

-- issue #315: remove Rapidhash accounts
UPDATE accounts_rapidhash_doge SET is_disabled=1;
UPDATE accounts_rapidhash_vtc SET is_disabled=1;

-- issue #289: remove ltcmine.ru accounts
UPDATE accounts_ltcmineru SET is_disabled=1;

-- issue #286: add NiceHash mining pool
CREATE TABLE accounts_nicehash (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_id varchar(255) not null,
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

-- issue #287: add WestHash mining pool
CREATE TABLE accounts_westhash (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_id varchar(255) not null,
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

-- issue #323: add Eobot mining pool
CREATE TABLE accounts_eobot (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_id varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

-- issue #282: add Hash-to-coins mining pool
CREATE TABLE accounts_hashtocoins (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

-- issue #324: add Reddcoin RDD cryptocurrency
DROP TABLE IF EXISTS reddcoin_blocks;

CREATE TABLE reddcoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #325: add Viacoin VIA cryptocurrency
DROP TABLE IF EXISTS viacoin_blocks;

CREATE TABLE viacoin_blocks (
  id int not null auto_increment primary key,
  created_at timestamp not null default current_timestamp,

  blockcount int not null,

  is_recent tinyint not null default 0,

  INDEX(is_recent)
);

-- issue #299: add BTClevels exchange
CREATE TABLE accounts_btclevels (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

-- --------------------------------------------------------------------------
-- upgrade statements from 0.29 to 0.30
-- NOTE make sure you set jobs_enabled=false while upgrading the site and executing these queries!
-- --------------------------------------------------------------------------
-- at some point, this can go into an upgrade script (#115); for now, just execute it as part of every upgrade step
DELETE FROM admin_messages WHERE message_type='version_check' AND is_read=0;

-- issue #328: add BitNZ accounts
CREATE TABLE accounts_bitnz (
  id int not null auto_increment primary key,
  user_id int not null,
  created_at timestamp not null default current_timestamp,
  last_queue timestamp,

  title varchar(255),
  api_username varchar(255) not null,
  api_key varchar(255) not null,
  api_secret varchar(255) not null,

  is_disabled tinyint not null default 0,
  failures tinyint not null default 0,
  first_failure timestamp null,
  is_disabled_manually tinyint not null default 0,

  INDEX(user_id), INDEX(last_queue), INDEX(is_disabled), INDEX(is_disabled_manually)
);

INSERT INTO exchanges SET name='bter';
UPDATE exchanges SET track_reported_currencies=1 WHERE name='bter';

ALTER TABLE securities_796 ADD is_disabled tinyint not null default 0;
ALTER TABLE securities_796 ADD failures tinyint not null default 0;
ALTER TABLE securities_796 ADD first_failure timestamp null;
ALTER TABLE securities_796 ADD INDEX(is_disabled);

UPDATE securities_796 SET is_disabled=1 WHERE name='bd';
INSERT INTO securities_796 SET name='rsm', title='RSM', api_name='rsm', user_id=100;

-- issue #337: disable BTCinve accounts
UPDATE accounts_btcinve SET is_disabled=1;
UPDATE accounts_individual_btcinve SET is_disabled=1;
DELETE FROM securities_update WHERE exchange='btcinve';
