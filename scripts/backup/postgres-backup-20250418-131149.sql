--
-- PostgreSQL database dump
--

-- Dumped from database version 15.12 (Debian 15.12-1.pgdg120+1)
-- Dumped by pg_dump version 15.12 (Debian 15.12-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: endpoint_access; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.endpoint_access (
    id integer NOT NULL,
    endpoint character varying(255) NOT NULL,
    access_count integer,
    last_accessed timestamp without time zone
);


ALTER TABLE public.endpoint_access OWNER TO postgres;

--
-- Name: endpoint_access_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.endpoint_access_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.endpoint_access_id_seq OWNER TO postgres;

--
-- Name: endpoint_access_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.endpoint_access_id_seq OWNED BY public.endpoint_access.id;


--
-- Name: endpoint_access id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.endpoint_access ALTER COLUMN id SET DEFAULT nextval('public.endpoint_access_id_seq'::regclass);


--
-- Data for Name: endpoint_access; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.endpoint_access (id, endpoint, access_count, last_accessed) FROM stdin;
2	/stats	26	2025-04-18 05:49:27.062867
1	/	26	2025-04-18 05:41:08.981106
\.


--
-- Name: endpoint_access_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.endpoint_access_id_seq', 2, true);


--
-- Name: endpoint_access endpoint_access_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.endpoint_access
    ADD CONSTRAINT endpoint_access_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--
