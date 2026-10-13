# Windows UI Screen Contract — Arabic-first RTL

## Navigation hierarchy

| Top level | Screen(s) | Core interaction | Phase(s) |
|---|---|---|---|
| تسجيل الدخول | Authentication, unlock | Offline username/password and session lock | 09 |
| الرئيسية | Dashboard | Total, Present, dynamic statuses, Unprepared; all-sites/site filter | 20 |
| التمام الشهري | Monthly grid | Four pinned RTL identity columns; fixed header; horizontally scrolling numbered weekday columns | 21,29 |
| الأرشيف | Sealed monthly archives | Month/site filter, search, historical Excel/print | 26,30 |
| الإدارة → الكشوفات | Auto import | Read workbook, preview, per-row rejection with reason | 14 |
| الإدارة → الكشوفات | Smart import | Worksheet/column mapping, custom columns, auto sites | 15 |
| الإدارة → الكشوفات | Export registry | All combined+site, combined only, site only; choose directory | 28 |
| الإدارة → الكشوفات | Modify layouts | Add/hide/rename/reorder columns without breaking field IDs | 16 |
| الإدارة → تمام القوة | Daily preparation | Multi-select, status, complete confirmation, cancellation confirmation | 18,19 |
| الإدارة → تمام القوة | Internal transfer | Right current site → arrow → left destination site; person multi-select/confirmation | 22 |
| الإدارة → تمام القوة | Modify force | Only name/number correction with preview + confirmation | 23 |
| الإدارة → تمام القوة | Reports | Search person by name/number, day/month attendance summary | 27 |
| الإدارة → تمام القوة | External transfer | Search, mandatory destination, historic archive | 24 |
| الإدارة → تمام القوة | Dismissal | Search, reason, five-second final confirmation, historic archive | 25 |
| الإدارة → الحالات والمواقع | Statuses | Defaults, add/customize labels, codes and color | 12 |
| الإدارة → الحالات والمواقع | Sites | Create, rename, deactivate with reassignment to protected undefined site | 11 |
| الإدارة | Audit log | Operator, operation, target, date and search filters | 32 |
| الإدارة | User management | General full, ordinary supervisors only, supervisor hidden | 31 |
| الإعدادات | Settings | Current identity/role, backups, 4PM scheduler, reset, version, logout | 33–36 |

## Shared desktop behavior

1. RTL navigation, Arabic labels and weekday abbreviations, appropriate mixed Arabic/English number rendering.
2. Keyboard navigation, focus states, native file/folder pickers and responsive desktop sizes.
3. Search: normalized Arabic letter forms and Arabic/Western digits; exact personnel IDs ranked ahead of partial matches.
4. No UI-only mutation: every operation invokes a validated, authorized transactional application service.
5. Never offer a fake functional button. Screens should only be added when their real backing use cases are implemented.
6. Support 1,000/5,000/10,000/20,000 records without full-grid rebuilds, using two-dimensional virtualization in monthly view.
7. Live and archived reporting always use correct effective-dated source, never overwrite sealed historical data.

## Phase 00 UI reality

Only a **read-only, clearly labelled foundation screen** is included. It is **not** the finished dashboard, login, or operational app. This distinction is intentional to satisfy the user's requirement against fake behavior.
