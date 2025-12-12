# Langda • Preferred Development Environment

**Langda** is a lightweight Ruby performance helper that automatically detects loops,
counts their iterations, measures execution time, and logs slow loops — all without
changing your application code.

It is designed for Rails and Ruby developers who want instant visibility into slow
loops such as `each`, `map`, `select`, `reject`, etc.

---

## ✨ Features

- 🟢 Auto-detects common Ruby loop methods
- 🔢 Counts loop iterations
- ⏱ Measures execution time using high-precision monotonic clock
- ⚠ Logs loops that cross the configurable slow threshold
- 🛡 Safe fallback — **never crashes your app**
- 🚀 Works in Rails, plain Ruby, Sidekiq, and background jobs
- 🔌 Zero configuration — install and use instantly

---
---
## ✨ Examples
- [Langda] Array#each → 42 iterations → 12.37 ms at app/models/user.rb:25
- [Langda] Hash#map → 8 iterations → 6.19 ms at app/services/report_builder.rb:12
---
## 📦 Installation

Add this line to your **Gemfile**:

```ruby
gem "langda"
