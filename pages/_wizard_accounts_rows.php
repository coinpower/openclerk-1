<?php

$count = 0;
foreach ($accounts as $a) {
	$count++;
	$balances = array();
	$balances_wallet = array();
	$balances_securities = array();
	$last_updated = null;
	$job = false;

	// an account may have multiple currency balances
	$all_exchanges = get_all_exchanges();
	foreach (array($a['exchange'], $a['exchange'] . '_wallet', $a['exchange'] . '_securities') as $exchange) {
		// only make requests for exchange keys that will actually ever exist
		if (isset($all_exchanges[$exchange])) {
			$q = db()->prepare("SELECT balances.* FROM balances WHERE user_id=? AND account_id=? AND exchange=? AND is_recent=1 ORDER BY currency ASC");
			$q->execute(array(user_id(), $a['id'], $exchange));
			while ($balance = $q->fetch()) {
				switch ($balance['exchange']) {
					case $a['exchange']:
						$balances[$balance['currency']] = $balance['balance'];
						break;
					case $a['exchange'] . "_wallet":
						$balances_wallet[$balance['currency']] = $balance['balance'];
						break;
					case $a['exchange'] . "_securities":
						$balances_securities[$balance['currency']] = $balance['balance'];
						break;
					default:
						throw new Exception("Unknown exchange '" . htmlspecialchars($balance['exchange']) . "' while retrieving account balances");
				}
				$last_updated = $balance['created_at'];
			}
		}
	}

	// was the last request successful?
	$q = db()->prepare("SELECT * FROM jobs
			WHERE user_id=? AND arg_id=? AND job_type=? AND is_executed=1 AND is_recent=1
			ORDER BY jobs.id DESC LIMIT 1");
	$q->execute(array(user_id(), $a['id'], $a['exchange']));
	$job = $q->fetch();
	if (!$last_updated && $job) {
		$last_updated = $job['executed_at'];
	}
	if ($job && $job['is_error']) {
		$q = db()->prepare("SELECT id,message FROM uncaught_exceptions WHERE job_id=? ORDER BY id DESC LIMIT 1");		// select the most recent exception too
		$q->execute(array($job['id']));
		$ue = $q->fetch();
		if ($ue) {
			$job['message'] = $ue['message'];
		}
	}

	// are we currently awaiting for a test callback?
	$q = db()->prepare("SELECT * FROM jobs WHERE user_id=? AND arg_id=? AND job_type=? AND is_executed=0 AND is_test_job=1 LIMIT 1");
	$q->execute(array(user_id(), $a['id'], $a['exchange']));
	$is_test_job = $q->fetch();

	$extra_display = array();
	if ($account_type['display_callback']) {
		$c = $account_type['display_callback'];
		$extra_display = $c($a);
	}

	// get the account type data
	$account_type_data = get_account_data($a['exchange']);

	$row_element_id = "row_" . $a['exchange'] . "_" . $a['id'];
	$is_disabled = isset($a['is_disabled']) && $a['is_disabled'];
?>
<?php if (!isset($is_in_callback)) { ?>
	<tr class="<?php echo $count % 2 == 0 ? "odd" : "even"; echo $is_disabled ? " disabled": ""; ?>" id="<?php echo htmlspecialchars($row_element_id); ?>">
<?php } ?>
		<td class="type"><?php echo htmlspecialchars($account_type['exchange_name_callback']($a['exchange']) . (isset($account_type_data['suffix']) ? $account_type_data['suffix'] : "")); ?></td>
		<td id="account<?php echo htmlspecialchars($a['id']); ?>" class="title">
			<span title="Title"><?php echo $a['title'] ? htmlspecialchars($a['title']) : "<i>" . ht("untitled") . "</i>"; ?></span>
			<form action="<?php echo htmlspecialchars(url_for('wizard_accounts_post')); ?>" method="post" style="display:none;">
			<input type="text" name="title" value="<?php echo htmlspecialchars($a['title']); ?>">
			<input type="submit" value="<?php echo ht("Update Title"); ?>">
			<input type="hidden" name="id" value="<?php echo htmlspecialchars($a['id']); ?>">
			<input type="hidden" name="type" value="<?php echo htmlspecialchars($a['exchange']); ?>">
			<input type="hidden" name="callback" value="<?php echo htmlspecialchars($account_type['url']); ?>">
			</form>
		</td>
		<?php foreach ($extra_display as $value) { ?>
			<td><?php echo $value; ?></td>
		<?php } ?>
		<?php foreach ($account_type['display_editable'] as $key => $callback) { ?>
		<td id="account<?php echo htmlspecialchars($a['id'] . "_" . $key); ?>" class="title headings">
			<span title="<?php echo htmlspecialchars($account_type['display_headings'][$key]); ?>"><?php echo $callback($a[$key]); ?></span>
			<form action="<?php echo htmlspecialchars(url_for('wizard_accounts_post')); ?>" method="post" style="display:none;">
			<input type="text" name="value" value="<?php echo htmlspecialchars($callback($a[$key])); ?>">
			<input type="submit" value="<?php echo ht("Update"); ?>">
			<input type="hidden" name="id" value="<?php echo htmlspecialchars($a['id']); ?>">
			<input type="hidden" name="type" value="<?php echo htmlspecialchars($a['exchange']); ?>">
			<input type="hidden" name="callback" value="<?php echo htmlspecialchars($account_type['url']); ?>">
			<input type="hidden" name="key" value="<?php echo htmlspecialchars($key); ?>">
			</form>
		</td>
		<?php } ?>
		<td class="added"><?php echo recent_format_html($a['created_at']); ?></td>
		<?php if ($account_type['has_balances']) { ?>
			<td class="last_checked <?php if ($job) echo ($job['is_error'] ? "job_error" : "job_success"); ?>">
				<?php echo recent_format_html($last_updated); ?>
				<?php if (isset($job['message']) && $job['message']) { ?>
				: <?php echo htmlspecialchars($job['message']); ?>
				<?php } ?>
			</td>
			<td class="balances"><?php
				$had_balance = false;
				echo "<ul>";
				foreach ($balances as $c => $value) {
					if ($value != 0) {
						$had_balance = true;
						echo "<li>" . currency_format($c, $value, 4) . "</li>\n";
					}
				}
				foreach ($balances_wallet as $c => $value) {
					if ($value != 0) {
						$had_balance = true;
						echo "<li>" . currency_format($c, $value, 4) . " " . ht("(wallet)"). "</li>\n";
					}
				}
				foreach ($balances_securities as $c => $value) {
					if ($value != 0) {
						$had_balance = true;
						echo "<li>" . currency_format($c, $value, 4) . " " . ht("(securities)") . "</li>\n";
					}
				}
				echo "</ul>";
				if (!$had_balance) echo "<i>-</i>";
				if ($is_disabled) echo " <i>" . ht("(disabled)") . "</i>";
			?></td>
		<?php } ?>
		<?php if ($account_type['hashrate']) {
			echo "<td class=\"balances hashrate\">";
			$found_hashrate = false;
			foreach (array($a['exchange'], $a['exchange'] . "_sha", $a['exchange'] . "_scrypt") as $exchange_key) {
				$q = db()->prepare("SELECT * FROM hashrates WHERE exchange=? AND account_id=? AND user_id=? AND is_recent=1 LIMIT 1");
				$q->execute(array($exchange_key, $a['id'], $a['user_id']));
				if ($mhash = $q->fetch()) {
					$found_hashrate = true;
					if (substr($mhash['exchange'], -strlen("_sha")) == "_sha") {
						echo number_format_autoprecision($mhash['mhash'], 1)  . " MH/s";
					} else if (substr($mhash['exchange'], -strlen("_sha")) == "_sha") {
						echo number_format_autoprecision($mhash['mhash'] * 1000, 1) . " KH/s";
					} else {
						echo $mhash['mhash'] ? (!(isset($a['khash']) && $a['khash']) ? number_format_autoprecision($mhash['mhash'], 1) . " MH/s" : number_format_autoprecision($mhash['mhash'] * 1000, 1) . " KH/s") : "-";
					}
					echo "<br>";
				}
			}
			if (!$found_hashrate) {
				echo "-";
			}
			echo "</td>";
		} ?>
		<?php
		if ($account_type['has_transactions']) {
			$q = db()->prepare("SELECT * FROM transaction_creators WHERE exchange=? AND account_id=?");
			$q->execute(array($a['exchange'], $a['id']));
			$creator = $q->fetch();
			$enabled = $creator && !$creator['is_disabled'];

			$q = db()->prepare("SELECT COUNT(*) AS c FROM transactions WHERE user_id=? AND exchange=? AND account_id=?");
			$q->execute(array(user_id(), $a['exchange'], $a['id']));
			$transaction_count = $q->fetch();
			?>
			<td class="buttons transactions">
				<?php if ($enabled) { ?>
				<form action="<?php echo htmlspecialchars(url_for('wizard_accounts_post')); ?>" method="post">
					<input type="hidden" name="id" value="<?php echo htmlspecialchars($a['id']); ?>">
					<input type="submit" name="remove_creator" value="<?php echo ht("Disable"); ?>" class="disable" onclick="return confirmCreatorDisable();" title="<?php echo ht("Disable transaction generation for this account"); ?>">
					<input type="hidden" name="type" value="<?php echo htmlspecialchars($a['exchange']); ?>">
					<input type="hidden" name="callback" value="<?php echo htmlspecialchars($account_type['url']); ?>">
				</form>
				<?php } else { ?>
				<form action="<?php echo htmlspecialchars(url_for('wizard_accounts_post')); ?>" method="post">
					<input type="hidden" name="id" value="<?php echo htmlspecialchars($a['id']); ?>">
					<input type="submit" name="create_creator" value="<?php echo ht("Enable"); ?>" class="enable" title="Enable transaction generation for this account">
					<input type="hidden" name="type" value="<?php echo htmlspecialchars($a['exchange']); ?>">
					<input type="hidden" name="callback" value="<?php echo htmlspecialchars($account_type['url']); ?>">
				</form>
			<?php } ?>
				<form action="<?php echo htmlspecialchars(url_for('wizard_accounts_post')); ?>" method="post">
					<input type="hidden" name="id" value="<?php echo htmlspecialchars($a['id']); ?>">
					<input type="submit" name="reset_creator" value="<?php echo ht("Reset"); ?>" class="reset" onclick="return confirmTransactionsReset();" title="<?php echo ht("Remove all historical transactions"); ?>">
					<input type="hidden" name="type" value="<?php echo htmlspecialchars($a['exchange']); ?>">
					<input type="hidden" name="callback" value="<?php echo htmlspecialchars($account_type['url']); ?>">
				</form>
				<span class="transaction-count">
					<a href="<?php echo htmlspecialchars(url_for('your_transactions', array('exchange' => $a['exchange'], 'account_id' => $a['id']))); ?>" class="view-transactions" title="<?php echo ht("View historical transactions"); ?>"><?php echo ht("View"); ?></a>
					(<?php echo number_format($transaction_count['c']); ?>)
				</span>
			</td>
		<?php } ?>
		<td class="buttons">
			<form action="<?php echo htmlspecialchars(url_for('wizard_accounts_post')); ?>" method="post">
				<input type="hidden" name="id" value="<?php echo htmlspecialchars($a['id']); ?>">
				<input type="submit" name="delete" value="<?php echo ht("Delete"); ?>" class="delete" onclick="return confirmAccountDelete();" title="<?php echo ht("Delete this account, removing all historical data"); ?>">
				<input type="hidden" name="type" value="<?php echo htmlspecialchars($a['exchange']); ?>">
				<input type="hidden" name="callback" value="<?php echo htmlspecialchars($account_type['url']); ?>">
			</form>
			<?php if (!$account_type_data['disabled'] && $account_type['can_test']) {
				if ($is_test_job) { ?>
					<span class="status_loading"><?php echo ht("Testing..."); ?></span>
						<?php if (!isset($is_in_callback)) { ?>
							<script type="text/javascript">
							$(document).ready(function() {
								initialise_wizard_test_callback($('#<?php echo htmlspecialchars($row_element_id); ?>'), <?php echo json_encode(url_for('wizard_accounts_callback', array('exchange' => $a['exchange'], 'id' => $a['id']))); ?>);
							});
							</script>
						<?php } ?>
					<?php } else { ?>
					<form action="<?php echo htmlspecialchars(url_for('wizard_accounts_post')); ?>" method="post">
						<input type="hidden" name="id" value="<?php echo htmlspecialchars($a['id']); ?>">
						<input type="submit" name="test" value="<?php echo ht("Test"); ?>" class="test" title="<?php echo ht("Request an immediate test of this account"); ?>">
						<input type="hidden" name="type" value="<?php echo htmlspecialchars($a['exchange']); ?>">
						<input type="hidden" name="callback" value="<?php echo htmlspecialchars($account_type['url']); ?>">
					</form>
					<?php if (isset($is_in_callback)) {
						// used to identify when a test has been successfully completed
						echo "<!-- successful test -->";
					} ?>
					<?php if ($is_disabled) { ?>
						<form action="<?php echo htmlspecialchars(url_for('wizard_accounts_post')); ?>" method="post">
							<input type="hidden" name="id" value="<?php echo htmlspecialchars($a['id']); ?>">
							<input type="submit" name="enable" value="<?php echo ht("Enable"); ?>" class="enable" title="<?php echo ht("Re-enable this account") ;?>">
							<input type="hidden" name="type" value="<?php echo htmlspecialchars($a['exchange']); ?>">
							<input type="hidden" name="callback" value="<?php echo htmlspecialchars($account_type['url']); ?>">
						</form>
					<?php } else if ($account_type_data['failure']) { ?>
						<form action="<?php echo htmlspecialchars(url_for('wizard_accounts_post')); ?>" method="post">
							<input type="hidden" name="id" value="<?php echo htmlspecialchars($a['id']); ?>">
							<input type="submit" name="disable" value="<?php echo ht("Disable"); ?>" class="disable" title="<?php echo ht("Disable this account, preserving any historical data"); ?>">
							<input type="hidden" name="type" value="<?php echo htmlspecialchars($a['exchange']); ?>">
							<input type="hidden" name="callback" value="<?php echo htmlspecialchars($account_type['url']); ?>">
						</form>
					<?php } ?>
				<?php } ?>
			<?php } ?>
		</td>
<?php if (!isset($is_in_callback)) { ?>
	</tr>
<?php } ?>
<?php } ?>
<?php if (!$accounts) { ?>
	<tr><td colspan="<?php echo 7 + count($account_type['display_headings']); ?>"><i><?php echo ht("(No :accounts defined.)", array(':accounts' => $account_type['accounts'])); ?></i></td></tr>
<?php } ?>
