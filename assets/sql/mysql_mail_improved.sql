CREATE TABLE `virtual_domains` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `virtual_domains_name` UNIQUE (`name`)
);
CREATE TABLE `virtual_users` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `domain_id` INT(11) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `password` VARCHAR(200) NOT NULL,
    `quota_limit` INT(20) NOT NULL,
    `receive_mail` BOOLEAN NOT NULL DEFAULT true,
    PRIMARY KEY (`id`),
    CONSTRAINT `virtual_users_email` UNIQUE (`domain_id`, `name`),
    CONSTRAINT `fk_users_domain` FOREIGN KEY (`domain_id`) REFERENCES `virtual_domains` (`id`)
);
CREATE TABLE `virtual_aliases` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `domain_id` INT(11) NOT NULL,
    `source` VARCHAR(100) NOT NULL,
    `destination` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `virtual_aliases_email` UNIQUE (`domain_id`, `source`),
    CONSTRAINT `fk_aliases_domain` FOREIGN KEY (`domain_id`) REFERENCES `virtual_domains` (`id`)
);
