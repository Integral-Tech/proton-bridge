package pmapi

import (
	"crypto/tls"
	"net"
	"net/http"
	"time"
)

type TLSDialer interface {
	DialTLS(network, address string) (conn net.Conn, err error)
}

// CreateTransportWithDialer creates an http.Transport that uses the given dialer to make TLS connections.
func CreateTransportWithDialer(dialer TLSDialer) *http.Transport {
	return &http.Transport{
		DialTLS: dialer.DialTLS,

		Proxy:                 http.ProxyFromEnvironment,
		MaxIdleConns:          100,
		IdleConnTimeout:       5 * time.Minute,
		ExpectContinueTimeout: 500 * time.Millisecond,

		// GODT-126: this was initially 10s but logs from users showed a significant number
		// were hitting this timeout, possibly due to flaky wifi taking >10s to reconnect.
		// Bumping to 30s for now to avoid this problem.
		ResponseHeaderTimeout: 30 * time.Second,

		// If we allow up to 30 seconds for response headers, it is reasonable to allow up
		// to 30 seconds for the TLS handshake to take place.
		TLSHandshakeTimeout: 30 * time.Second,
	}
}

// BasicTLSDialer implements TLSDialer.
type BasicTLSDialer struct{}

// NewBasicTLSDialer returns a new BasicTLSDialer.
func NewBasicTLSDialer() *BasicTLSDialer {
	return &BasicTLSDialer{}
}

// DialTLS returns a connection to the given address using the given network.
func (b *BasicTLSDialer) DialTLS(network, address string) (conn net.Conn, err error) {
	dialer := &net.Dialer{Timeout: 10 * time.Second}

	var tlsConfig *tls.Config = nil

	// If we are not dialing the standard API then we should skip cert verification checks.
	if address != rootURL {
		tlsConfig = &tls.Config{InsecureSkipVerify: true} // nolint[gosec]
	}

	return tls.DialWithDialer(dialer, network, address, tlsConfig)
}
