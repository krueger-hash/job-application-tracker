CREATE TYPE status AS ENUM(
    'planned',
    'applied',
    'interview',
    'offer',
    'rejected'
);

CREATE TABLE app_user(
    id uuid PRIMARY KEY,
    email varchar(255) UNIQUE NOT NULL,
    locale varchar(255) NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE application(
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    archived boolean NOT NULL DEFAULT false,
    company varchar(255) NOT NULL,
    role varchar(255) NOT NULL,
    deadline timestamptz,
    notes text,
    salary integer,
    description text,
    status status NOT NULL default 'planned',
    job_link text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE contact(
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    name varchar(255) NOT NULL,
    role varchar(255),
    email varchar(255),
    address varchar(255),
    phone varchar(255),
    contact_link text,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE application_contact(
    application_id uuid NOT NULL REFERENCES application(id) ON DELETE CASCADE,
    contact_id uuid NOT NULL REFERENCES contact(id) ON DELETE CASCADE,
    PRIMARY KEY (application_id, contact_id)
);

CREATE TABLE interview(
    id uuid PRIMARY KEY,
    application_id uuid NOT NULL REFERENCES application(id) ON DELETE CASCADE,
    date timestamptz NOT NULL,
    location varchar(255),
    link text,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE document(
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
    application_id uuid NOT NULL REFERENCES application(id) ON DELETE CASCADE,
    document_name varchar(255) NOT NULL,
    s3_key text NOT NULL,
    file_type varchar(255) NOT NULL,
    file_size BIGINT NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE status_change(
    id uuid PRIMARY KEY,
    application_id uuid NOT NULL REFERENCES application(id) ON DELETE CASCADE,
    to_status status NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
