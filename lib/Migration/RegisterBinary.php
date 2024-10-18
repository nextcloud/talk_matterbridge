<?php

declare(strict_types=1);
/**
 * SPDX-FileCopyrightText: 2022-2024 Nextcloud GmbH and Nextcloud contributors
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

namespace OCA\TalkMatterbridge\Migration;

use OCP\IConfig;
use OCP\Migration\IOutput;
use OCP\Migration\IRepairStep;

class RegisterBinary implements IRepairStep {
	public const VERSION = '1.26.0';

	public function __construct(
		protected IConfig $config,
	) {
	}

	public function getName(): string {
		return 'Register the Matterbridge binary';
	}

	public function run(IOutput $output): void {
		$binaryDir = dirname(__DIR__, 2) . '/bin/';

		if (PHP_INT_SIZE === 8) {
			$binaryPath = $binaryDir . 'matterbridge-' . self::VERSION . '-linux-arm64';
			$version = $this->testBinary($binaryPath);
			if ($version === null) {
				$binaryPath = $binaryDir . 'matterbridge-' . self::VERSION . '-linux-64bit';
				$version = $this->testBinary($binaryPath);
				if ($version === null) {
					$output->warning('Failed to read version from matterbridge binary');
				}
			}
		} else {
			$binaryPath = $binaryDir . 'matterbridge-' . self::VERSION . '-linux-32bit';
			$version = $this->testBinary($binaryPath);
			if ($version === null) {
				$output->warning('Failed to read version from matterbridge binary');
			} else {
				$output->info('Found matterbridge binary version: ' . $version);
			}
		}

		// Write the app config
		$this->config->setAppValue('spreed', 'matterbridge_binary', $binaryPath);
	}

	protected function testBinary(string $binaryPath): ?string {
		// Make binary executable
		chmod($binaryPath, 0755);

		$cmd = escapeshellcmd($binaryPath) . ' ' . escapeshellarg('-version');
		try {
			@exec($cmd, $output, $returnCode);
		} catch (\Throwable $e) {
		}

		if ($returnCode !== 0) {
			return null;
		}

		return trim(implode("\n", $output));
	}
}
