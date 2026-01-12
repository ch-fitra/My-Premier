package middleware

// This file previously contained role-related middleware that depended on the
// user module, which created an import cycle. The role-based middleware has
// been moved into the user module (see internal/modules/user/role_middleware.go)
// and shared auth context helpers are provided by the internal/common/authcontext
// package. This file is intentionally left without executable code to avoid
// reintroducing the cycle while keeping the package structure stable.

