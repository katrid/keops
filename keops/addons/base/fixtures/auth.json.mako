[
    {
        "model": "auth.group",
        "data-id": "auth-group-admin",
    	"fields" : {
            "name": "${_('Administrators')}"
        }
    },
    {
        "model": "base.user",
        "data-id": "auth-user-admin",
    	"fields" : {
    		"company": ["main-company"],
    		"name": "${_('Administrator')}",
            "username": "${_('admin')}",
            "first_name": "${_('Administrator')}",
            "raw_password": "admin",
            "is_superuser": true,
            "is_staff": true,
            "email": "admin@example.com"
        }
    }
]