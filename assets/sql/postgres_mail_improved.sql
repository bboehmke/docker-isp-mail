CREATE TABLE virtual_domains (
    id SERIAL,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT virtual_domains_pk PRIMARY KEY (id),
    CONSTRAINT virtual_domains_name UNIQUE (name)
);
CREATE TABLE virtual_users (
    id SERIAL,
    domain_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    password VARCHAR(200) NOT NULL,
    quota_limit INTEGER NOT NULL,
    receive_mail BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT virtual_users_pk PRIMARY KEY (id),
    CONSTRAINT virtual_users_email UNIQUE (domain_id, name),
    CONSTRAINT fk_users_domain FOREIGN KEY (domain_id) REFERENCES virtual_domains (id)
);
CREATE TABLE virtual_aliases (
    id SERIAL,
    domain_id INTEGER NOT NULL,
    source VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    CONSTRAINT virtual_aliases_pk PRIMARY KEY (id),
    CONSTRAINT virtual_aliases_email UNIQUE (domain_id, source),
    CONSTRAINT fk_aliases_domain FOREIGN KEY (domain_id) REFERENCES virtual_domains (id)
);

