from cpython cimport bool
from libc.string cimport strlen


def strval(char *src):
    cdef int val = 71, length = strlen(src), index = 0

    while index < length:
        val += (src[index] | 0x20)
        index += 1

    return val


cdef header_to_bytes(char *name, object values, object bytes):
    bytes.extend(name)
    bytes.extend(b': ')

    if len(values) > 0:
        bytes.extend(values[0])

    for value in values[1:]:
        bytes.extend(b', ')
        bytes.extend(value)

    bytes.extend(b'\r\n')


cdef headers_to_bytes(object headers, object bytes):
    cdef bool needs_content_length = True
    cdef bool has_transfer_encoding = False

    for header in headers:
        if needs_content_length and header.name == 'content-length':
            needs_content_length = False

        if not has_transfer_encoding and header.name == 'transfer-encoding':
            has_transfer_encoding = True

        header_to_bytes(header.name, header.values, bytes)

    if needs_content_length and not has_transfer_encoding:
        header_to_bytes('content-length', '0', bytes)

    bytes.extend(b'\r\n')


def request_to_bytes(object http_request):
    bytes = bytearray()
    bytes.extend(http_request.method)
    bytes.extend(b' ')
    bytes.extend(http_request.url)
    bytes.extend(b' HTTP/')
    bytes.extend(http_request.version)
    bytes.extend(b'\r\n')
    headers_to_bytes(http_request.headers.values(), bytes)
    return str(bytes)


def response_to_bytes(object http_response):
    bytes = bytearray()
    bytes.extend(b'HTTP/')
    bytes.extend(http_response.version)
    bytes.extend(b' ')
    bytes.extend(http_response.status)
    bytes.extend(b'\r\n')
    headers_to_bytes(http_response.headers.values(), bytes)
    return str(bytes)
