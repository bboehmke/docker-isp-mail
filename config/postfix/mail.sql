CREATE TABLE IF NOT EXISTS `virtual_domains` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`id`)
);
CREATE TABLE IF NOT EXISTS `virtual_users` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `domain_id` INT(11) UNSIGNED NOT NULL,
    `password` VARCHAR(128) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `email` (`name`, `domain_id`),
    INDEX `domain_id` (`domain_id`)
);
CREATE TABLE IF NOT EXISTS `virtual_aliases` (
    `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
    `domain_id` INT(11) UNSIGNED NOT NULL,
    `source` VARCHAR(100) NOT NULL,
    `destination` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE INDEX `email` (`domain_id`, `source`),
    INDEX `domain_id` (`domain_id`)
);