
using Microsoft.AspNetCore.Authorization;

namespace Storix.Api.Security;

[AttributeUsage(
    AttributeTargets.Class | AttributeTargets.Method,
    AllowMultiple = true,
    Inherited = true)]
public sealed class HasPermissionAttribute : AuthorizeAttribute
{
    public const string Prefix = "Permission:";

    public HasPermissionAttribute(string permission)
    {
        if (string.IsNullOrWhiteSpace(permission))
            throw new ArgumentException(
                "Permission code cannot be empty.",
                nameof(permission));

        Policy = Prefix + permission;
    }
}
