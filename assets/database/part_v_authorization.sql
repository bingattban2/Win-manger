-- PART V: apply AFTER schema_v1.sql and seed_v1.sql, inside an encrypted
-- database initialization/migration transaction. This file contains only a
-- precomputed salted password verifier; it does NOT contain a plaintext secret.
-- The SQL is also executed by ephemeral SQLite regression tests.

CREATE TRIGGER IF NOT EXISTS trg_only_foundation_can_be_general_admin
BEFORE INSERT ON app_users
WHEN NEW.role='GENERAL_ADMIN' AND NEW.id<>'00000000-0000-4000-8000-000000000099'
BEGIN SELECT RAISE(ABORT,'only system administrator can hold general role'); END;

CREATE TRIGGER IF NOT EXISTS trg_foundation_account_immutable_identity
BEFORE UPDATE ON app_users
WHEN OLD.id='00000000-0000-4000-8000-000000000099'
AND (
  NEW.id<>OLD.id OR NEW.username<>OLD.username OR
  NEW.normalized_username<>OLD.normalized_username OR
  NEW.person_id IS NOT NULL OR NEW.role<>'GENERAL_ADMIN' OR
  NEW.is_active<>1 OR NEW.is_deleted<>0 OR
  NEW.password_hash<>OLD.password_hash
)
BEGIN SELECT RAISE(ABORT,'protected foundational account'); END;

CREATE TRIGGER IF NOT EXISTS trg_account_no_hard_delete
BEFORE DELETE ON app_users
BEGIN SELECT RAISE(ABORT,'account history must use soft deletion'); END;

CREATE TRIGGER IF NOT EXISTS trg_account_no_rename_or_role_change
BEFORE UPDATE ON app_users
WHEN OLD.id<>'00000000-0000-4000-8000-000000000099'
AND (NEW.id<>OLD.id OR NEW.username<>OLD.username OR
     NEW.normalized_username<>OLD.normalized_username OR
     NEW.role<>OLD.role OR NEW.person_id IS NOT OLD.person_id OR
     NEW.created_by IS NOT OLD.created_by OR NEW.created_at<>OLD.created_at)
BEGIN SELECT RAISE(ABORT,'account identity and role are immutable'); END;

CREATE TRIGGER IF NOT EXISTS trg_account_no_resurrection
BEFORE UPDATE ON app_users
WHEN (OLD.is_deleted=1 AND NEW.is_deleted=0) OR
     (OLD.is_active=0 AND NEW.is_active=1)
BEGIN SELECT RAISE(ABORT,'deleted or disabled account cannot be reactivated'); END;

CREATE TRIGGER IF NOT EXISTS trg_account_reserved_foundation_identity
BEFORE INSERT ON app_users
WHEN NEW.normalized_username='adwas' AND NEW.id<>'00000000-0000-4000-8000-000000000099'
BEGIN SELECT RAISE(ABORT,'reserved system username'); END;

INSERT INTO app_users(id,username,normalized_username,person_id,role,
  password_hash,is_active,is_deleted,created_by,created_at,updated_at)
SELECT '00000000-0000-4000-8000-000000000099','adwas','adwas',NULL,'GENERAL_ADMIN',
 'pbkdf2_sha256$210000$VmrezvLtEP6CecM2PMKPYg==$oM0M8QinKBZMQ8HgsVF07x3y0bs4lHD/RcRLLTv3EfI=',
 1,0,NULL,'2026-01-01T00:00:00Z','2026-01-01T00:00:00Z'
WHERE NOT EXISTS (SELECT 1 FROM app_users WHERE id='00000000-0000-4000-8000-000000000099');
