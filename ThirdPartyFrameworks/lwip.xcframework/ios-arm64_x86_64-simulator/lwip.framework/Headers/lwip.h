#ifndef lwip_h
#define lwip_h

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

//! Project version number for lwip.
FOUNDATION_EXPORT double lwipVersionNumber;

//! Project version string for lwip.
FOUNDATION_EXPORT const unsigned char lwipVersionString[];

/* Modules initialization */
void lwip_init(void);

void sys_check_timeouts(void);
void sys_restart_timeouts(void);

/* Define generic types used in lwIP */
typedef unsigned   char    u8_t;
typedef signed     char    s8_t;
typedef unsigned   short   u16_t;
typedef signed     short   s16_t;
typedef unsigned   int     u32_t;
typedef signed     int     s32_t;

typedef unsigned long mem_ptr_t;


typedef s8_t err_t;

/* Definitions for error constants. */

#define ERR_OK          0    /* No error, everything OK. */
#define ERR_MEM        -1    /* Out of memory error.     */
#define ERR_BUF        -2    /* Buffer error.            */
#define ERR_TIMEOUT    -3    /* Timeout.                 */
#define ERR_RTE        -4    /* Routing problem.         */
#define ERR_INPROGRESS -5    /* Operation in progress    */
#define ERR_VAL        -6    /* Illegal value.           */
#define ERR_WOULDBLOCK -7    /* Operation would block.   */
#define ERR_USE        -8    /* Address in use.          */
#define ERR_ISCONN     -9    /* Already connected.       */

#define ERR_IS_FATAL(e) ((e) < ERR_ISCONN)

#define ERR_ABRT       -10   /* Connection aborted.      */
#define ERR_RST        -11   /* Connection reset.        */
#define ERR_CLSD       -12   /* Connection closed.       */
#define ERR_CONN       -13   /* Not connected.           */

#define ERR_ARG        -14   /* Illegal argument.        */

#define ERR_IF         -15   /* Low-level netif error    */

/* This is the aligned version of ip_addr_t,
 used as local variable, on the stack, etc. */
struct ip_addr {
    u32_t addr;
};
typedef struct ip_addr ip_addr_t;

extern const ip_addr_t ip_addr_any;
extern const ip_addr_t ip_addr_broadcast;

/** IP_ADDR_ can be used as a fixed IP address
 *  for the wildcard and the broadcast address
 */
#define IP_ADDR_ANY         ((ip_addr_t *)&ip_addr_any)
#define IP_ADDR_BROADCAST   ((ip_addr_t *)&ip_addr_broadcast)

/** 255.255.255.255 */
#define IPADDR_NONE         ((u32_t)0xffffffffUL)
/** 127.0.0.1 */
#define IPADDR_LOOPBACK     ((u32_t)0x7f000001UL)
/** 0.0.0.0 */
#define IPADDR_ANY          ((u32_t)0x00000000UL)

typedef enum {
    PBUF_RAM, /* pbuf data is stored in RAM */
    PBUF_ROM, /* pbuf data is stored in ROM */
    PBUF_REF, /* pbuf comes from the pbuf pool */
    PBUF_POOL /* pbuf payload refers to RAM */
} pbuf_type;

struct pbuf {
    /** next pbuf in singly linked pbuf chain */
    struct pbuf *next;
    
    /** pointer to the actual data in the buffer */
    void *payload;
    
    /**
     * total length of this buffer and all next buffers in chain
     * belonging to the same packet.
     *
     * For non-queue packet chains this is the invariant:
     * p->tot_len == p->len + (p->next? p->next->tot_len: 0)
     */
    u16_t tot_len;
    
    /** length of this buffer */
    u16_t len;
    
    /** pbuf_type as u8_t instead of enum to save space */
    u8_t /*pbuf_type*/ type;
    
    /** misc flags */
    u8_t flags;
    
    /**
     * the reference count always equals the number of pointers
     * that refer to this pbuf. This can be pointers from an application,
     * the stack itself, or pbuf->next pointers from a chain.
     */
    u16_t ref;
};

typedef enum {
    PBUF_TRANSPORT,
    PBUF_IP,
    PBUF_LINK,
    PBUF_RAW
} pbuf_layer;

struct pbuf *pbuf_alloc(pbuf_layer l, u16_t length, pbuf_type type);
void pbuf_realloc(struct pbuf *p, u16_t size);
u8_t pbuf_header(struct pbuf *p, s16_t header_size);
void pbuf_ref(struct pbuf *p);
u8_t pbuf_free(struct pbuf *p);
u8_t pbuf_clen(struct pbuf *p);
void pbuf_cat(struct pbuf *head, struct pbuf *tail);
void pbuf_chain(struct pbuf *head, struct pbuf *tail);
struct pbuf *pbuf_dechain(struct pbuf *p);
err_t pbuf_copy(struct pbuf *p_to, struct pbuf *p_from);
u16_t pbuf_copy_partial(struct pbuf *p, void *dataptr, u16_t len, u16_t offset);
err_t pbuf_take(struct pbuf *buf, const void *dataptr, u16_t len);


/* This is the common part of all PCB types. It needs to be at the
 beginning of a PCB type definition. It is located here so that
 changes to this common part are made in one location instead of
 having to change all PCB structs. */
#define IP_PCB \
/* ip addresses in network byte order */ \
ip_addr_t local_ip; \
ip_addr_t remote_ip; \
/* Socket options */  \
u8_t so_options;      \
/* Type Of Service */ \
u8_t tos;              \
/* Time To Live */     \
u8_t ttl

#define DEF_ACCEPT_CALLBACK  tcp_accept_fn accept;

/**
 * members common to struct tcp_pcb and struct tcp_listen_pcb
 */
#define TCP_PCB_COMMON(type) \
type *next; /* for the linked list */ \
void *callback_arg; \
/* the accept callback for listen- and normal pcbs, if LWIP_CALLBACK_API */ \
DEF_ACCEPT_CALLBACK \
enum tcp_state state; /* TCP state */ \
u8_t prio; \
/* ports are in host byte order */ \
u16_t local_port

enum tcp_state {
    CLOSED      = 0,
    LISTEN      = 1,
    SYN_SENT    = 2,
    SYN_RCVD    = 3,
    ESTABLISHED = 4,
    FIN_WAIT_1  = 5,
    FIN_WAIT_2  = 6,
    CLOSE_WAIT  = 7,
    CLOSING     = 8,
    LAST_ACK    = 9,
    TIME_WAIT   = 10
};

struct tcp_pcb;
/** Function prototype for tcp accept callback functions. Called when a new
 * connection can be accepted on a listening pcb.
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param newpcb The new connection pcb
 * @param err An error code if there has been an error accepting.
 *            Only return ERR_ABRT if you have called tcp_abort from within the
 *            callback function!
 */
typedef err_t (*tcp_accept_fn)(void *arg, struct tcp_pcb *newpcb, err_t err);

/* the TCP protocol control block */
struct tcp_pcb {
    /** common PCB members */
    IP_PCB;
    /** protocol specific PCB members */
    TCP_PCB_COMMON(struct tcp_pcb);
    
    /* ports are in host byte order */
    u16_t remote_port;
};

/** Function prototype for tcp receive callback functions. Called when data has
 * been received.
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param tpcb The connection pcb which received data
 * @param p The received data (or NULL when the connection has been closed!)
 * @param err An error code if there has been an error receiving
 *            Only return ERR_ABRT if you have called tcp_abort from within the
 *            callback function!
 */
typedef err_t (*tcp_recv_fn)(void *arg, struct tcp_pcb *tpcb,
                             struct pbuf *p, err_t err);

/** Function prototype for tcp sent callback functions. Called when sent data has
 * been acknowledged by the remote side. Use it to free corresponding resources.
 * This also means that the pcb has now space available to send new data.
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param tpcb The connection pcb for which data has been acknowledged
 * @param len The amount of bytes acknowledged
 * @return ERR_OK: try to send some data by calling tcp_output
 *            Only return ERR_ABRT if you have called tcp_abort from within the
 *            callback function!
 */
typedef err_t (*tcp_sent_fn)(void *arg, struct tcp_pcb *tpcb,
                             u16_t len);

/** Function prototype for tcp poll callback functions. Called periodically as
 * specified by @see tcp_poll.
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param tpcb tcp pcb
 * @return ERR_OK: try to send some data by calling tcp_output
 *            Only return ERR_ABRT if you have called tcp_abort from within the
 *            callback function!
 */
typedef err_t (*tcp_poll_fn)(void *arg, struct tcp_pcb *tpcb);

/** Function prototype for tcp error callback functions. Called when the pcb
 * receives a RST or is unexpectedly closed for any other reason.
 *
 * @note The corresponding pcb is already freed when this callback is called!
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param err Error code to indicate why the pcb has been closed
 *            ERR_ABRT: aborted through tcp_abort or by a TCP timer
 *            ERR_RST: the connection was reset by the remote host
 */
typedef void  (*tcp_err_fn)(void *arg, err_t err);

/** Function prototype for tcp connected callback functions. Called when a pcb
 * is connected to the remote side after initiating a connection attempt by
 * calling tcp_connect().
 *
 * @param arg Additional argument to pass to the callback function (@see tcp_arg())
 * @param tpcb The connection pcb which is connected
 * @param err An unused error code, always ERR_OK currently ;-) TODO!
 *            Only return ERR_ABRT if you have called tcp_abort from within the
 *            callback function!
 *
 * @note When a connection attempt fails, the error callback is currently called!
 */
typedef err_t (*tcp_connected_fn)(void *arg, struct tcp_pcb *tpcb, err_t err);




/* Application program's interface: */
struct tcp_pcb * tcp_new     (void);

void             tcp_arg     (struct tcp_pcb *pcb, void *arg);
void             tcp_accept  (struct tcp_pcb *pcb, tcp_accept_fn accept);
void             tcp_recv    (struct tcp_pcb *pcb, tcp_recv_fn recv);
void             tcp_sent    (struct tcp_pcb *pcb, tcp_sent_fn sent);
void             tcp_poll    (struct tcp_pcb *pcb, tcp_poll_fn poll, u8_t interval);
void             tcp_err     (struct tcp_pcb *pcb, tcp_err_fn err);

#define          tcp_mss(pcb)             (((pcb)->flags & TF_TIMESTAMP) ? ((pcb)->mss - 12)  : (pcb)->mss)
#define          tcp_sndbuf(pcb)          ((pcb)->snd_buf)
#define          tcp_sndqueuelen(pcb)     ((pcb)->snd_queuelen)
#define          tcp_nagle_disable(pcb)   ((pcb)->flags |= TF_NODELAY)
#define          tcp_nagle_enable(pcb)    ((pcb)->flags &= ~TF_NODELAY)
#define          tcp_nagle_disabled(pcb)  (((pcb)->flags & TF_NODELAY) != 0)

#if TCP_LISTEN_BACKLOG
#define          tcp_accepted(pcb) do { \
LWIP_ASSERT("pcb->state == LISTEN (called for wrong pcb?)", pcb->state == LISTEN); \
(((struct tcp_pcb_listen *)(pcb))->accepts_pending--); } while(0)
#else  /* TCP_LISTEN_BACKLOG */
#define          tcp_accepted(pcb) LWIP_ASSERT("pcb->state == LISTEN (called for wrong pcb?)", \
(pcb)->state == LISTEN)
#endif /* TCP_LISTEN_BACKLOG */

void             tcp_recved  (struct tcp_pcb *pcb, u16_t len);
err_t            tcp_bind    (struct tcp_pcb *pcb, ip_addr_t *ipaddr,
                              u16_t port);
err_t            tcp_connect (struct tcp_pcb *pcb, ip_addr_t *ipaddr,
                              u16_t port, tcp_connected_fn connected);

struct tcp_pcb * tcp_listen_with_backlog(struct tcp_pcb *pcb, u8_t backlog);
#define          tcp_listen(pcb) tcp_listen_with_backlog(pcb, TCP_DEFAULT_LISTEN_BACKLOG)

void             tcp_abort (struct tcp_pcb *pcb);
err_t            tcp_close   (struct tcp_pcb *pcb);
err_t            tcp_shutdown(struct tcp_pcb *pcb, int shut_rx, int shut_tx);

/* Flags for "apiflags" parameter in tcp_write */
#define TCP_WRITE_FLAG_COPY 0x01
#define TCP_WRITE_FLAG_MORE 0x02

err_t            tcp_write   (struct tcp_pcb *pcb, const void *dataptr, u16_t len,
                              u8_t apiflags);

void             tcp_setprio (struct tcp_pcb *pcb, u8_t prio);

#define TCP_PRIO_MIN    1
#define TCP_PRIO_NORMAL 64
#define TCP_PRIO_MAX    127

err_t            tcp_output  (struct tcp_pcb *pcb);

void tcp_accepted_c(struct tcp_pcb *pcb);
#define TCP_DEFAULT_LISTEN_BACKLOG 0xff
struct tcp_pcb * tcp_listen_with_backlog(struct tcp_pcb *pcb, u8_t backlog);


/** The list of network interfaces. */
extern struct netif *netif_list;
/** The default network interface. */
extern struct netif *netif_default;

struct netif;
/** Function prototype for netif init functions. Set up flags and output/linkoutput
 * callback functions in this function.
 *
 * @param netif The netif to initialize
 */
typedef err_t (*netif_init_fn)(struct netif *netif);
/** Function prototype for netif->input functions. This function is saved as 'input'
 * callback function in the netif struct. Call it when a packet has been received.
 *
 * @param p The received packet, copied into a pbuf
 * @param inp The netif which received the packet
 */
typedef err_t (*netif_input_fn)(struct pbuf *p, struct netif *inp);
/** Function prototype for netif->output functions. Called by lwIP when a packet
 * shall be sent. For ethernet netif, set this to 'etharp_output' and set
 * 'linkoutput'.
 *
 * @param netif The netif which shall send a packet
 * @param p The packet to send (p->payload points to IP header)
 * @param ipaddr The IP address to which the packet shall be sent
 */
typedef err_t (*netif_output_fn)(struct netif *netif, struct pbuf *p,
                                 ip_addr_t *ipaddr);
/** Function prototype for netif->linkoutput functions. Only used for ethernet
 * netifs. This function is called by ARP when a packet shall be sent.
 *
 * @param netif The netif which shall send a packet
 * @param p The packet to send (raw ethernet packet)
 */
typedef err_t (*netif_linkoutput_fn)(struct netif *netif, struct pbuf *p);
/** Function prototype for netif status- or link-callback functions. */
typedef void (*netif_status_callback_fn)(struct netif *netif);
/** Function prototype for netif igmp_mac_filter functions */
typedef err_t (*netif_igmp_mac_filter_fn)(struct netif *netif,
                                          ip_addr_t *group, u8_t action);

/** must be the maximum of all used hardware address lengths
 across all types of interfaces in use */
#define NETIF_MAX_HWADDR_LEN 6U

struct netif {
    /** pointer to next in linked list */
    struct netif *next;
    
    /** IP address configuration in network byte order */
    ip_addr_t ip_addr;
    ip_addr_t netmask;
    ip_addr_t gw;
    
    /** This function is called by the network device driver
     *  to pass a packet up the TCP/IP stack. */
    netif_input_fn input;
    /** This function is called by the IP module when it wants
     *  to send a packet on the interface. This function typically
     *  first resolves the hardware address, then sends the packet. */
    netif_output_fn output;
    /** This function is called by the ARP module when it wants
     *  to send a packet on the interface. This function outputs
     *  the pbuf as-is on the link medium. */
    netif_linkoutput_fn linkoutput;
#if LWIP_NETIF_STATUS_CALLBACK
    /** This function is called when the netif state is set to up or down
     */
    netif_status_callback_fn status_callback;
#endif /* LWIP_NETIF_STATUS_CALLBACK */
#if LWIP_NETIF_LINK_CALLBACK
    /** This function is called when the netif link is set to up or down
     */
    netif_status_callback_fn link_callback;
#endif /* LWIP_NETIF_LINK_CALLBACK */
#if LWIP_NETIF_REMOVE_CALLBACK
    /** This function is called when the netif has been removed */
    netif_status_callback_fn remove_callback;
#endif /* LWIP_NETIF_REMOVE_CALLBACK */
    /** This field can be set by the device driver and could point
     *  to state information for the device. */
    void *state;
#if LWIP_DHCP
    /** the DHCP client state information for this netif */
    struct dhcp *dhcp;
#endif /* LWIP_DHCP */
#if LWIP_AUTOIP
    /** the AutoIP client state information for this netif */
    struct autoip *autoip;
#endif
#if LWIP_NETIF_HOSTNAME
    /* the hostname for this netif, NULL is a valid value */
    char*  hostname;
#endif /* LWIP_NETIF_HOSTNAME */
    /** maximum transfer unit (in bytes) */
    u16_t mtu;
    /** number of bytes used in hwaddr */
    u8_t hwaddr_len;
    /** link level hardware address of this interface */
    u8_t hwaddr[NETIF_MAX_HWADDR_LEN];
    /** flags (see NETIF_FLAG_ above) */
    u8_t flags;
    /** descriptive abbreviation */
    char name[2];
    /** number of this interface */
    u8_t num;
#if LWIP_SNMP
    /** link type (from "snmp_ifType" enum from snmp.h) */
    u8_t link_type;
    /** (estimate) link speed */
    u32_t link_speed;
    /** timestamp at last change made (up/down) */
    u32_t ts;
    /** counters */
    u32_t ifinoctets;
    u32_t ifinucastpkts;
    u32_t ifinnucastpkts;
    u32_t ifindiscards;
    u32_t ifoutoctets;
    u32_t ifoutucastpkts;
    u32_t ifoutnucastpkts;
    u32_t ifoutdiscards;
#endif /* LWIP_SNMP */
#if LWIP_IGMP
    /** This function could be called to add or delete a entry in the multicast
     filter table of the ethernet MAC.*/
    netif_igmp_mac_filter_fn igmp_mac_filter;
#endif /* LWIP_IGMP */
#if LWIP_NETIF_HWADDRHINT
    u8_t *addr_hint;
#endif /* LWIP_NETIF_HWADDRHINT */
#if ENABLE_LOOPBACK
    /* List of packets to be queued for ourselves. */
    struct pbuf *loop_first;
    struct pbuf *loop_last;
#if LWIP_LOOPBACK_MAX_PBUFS
    u16_t loop_cnt_current;
#endif /* LWIP_LOOPBACK_MAX_PBUFS */
#endif /* ENABLE_LOOPBACK */
};


#endif /* lwip_h */
